import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ambulance/components/drawer.dart';
import 'package:ambulance/pages/accept_reject.dart';
import 'package:ambulance/pages/delivery_state.dart';
import 'package:ambulance/pages/notification_services.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  bool switchValue = false;
  // bool showButton = false;

  Location location = Location();
  double userLatitude = 0.0;
  double userLongitude = 0.0;
  String username = "";
  String userId = "";
  String userToken = "";
  bool isDeliveryStarted = false;
  bool isActive = false;
  bool isnewTracking = false;
  bool _initialized = false;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController emailController = TextEditingController();
  final NotificationServices notificationServices =
      NotificationServices.instance;
  StreamSubscription<LocationData>? locationSubscription;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference userCollection;
  late CollectionReference userLocationCollection;
  late CollectionReference driverCollection;
  late CollectionReference trackingCollection;

  //logout function
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    trackingCollection = firestore.collection('Tracking');
    driverCollection = firestore.collection('DriverLocation');
    _getLocation();
    super.initState();
    notificationServices.requestNotificationPermission();
    // notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    // notificationServices.isTokenRefresh();
    notificationServices.getDeviceToken().then((value) {
      print('Device Token:');
      print(value);
      setToken(currentUser, value);
    });

    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification?.body.toString());
        // print(message.data['email'].toString());
      }
      if (Platform.isAndroid) {
        notificationServices.initLocalNotifications(context, message);
        notificationServices.showNotification(message);
      }
      setUserDetails(message.data['email']);
      setState(() {
        userId = message.data['email'];
        print(userId);
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AcceptReject(userId: message.data['email'])));
    });

    notificationServices.setupInteractMessage(context);

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Got message while in the foreground.');
    //   print('Message Data: ${message.data}');
    //   if (message.notification != null) {
    //     print('Message also contained a notification: ${message.notification}');
    //   }
    //   setUserDetails(message.data['email']);
    //   setState(() {
    //     showButton = true;
    //     userId = message.data['email'];
    //     print(userId);
    //   });
    // });

    // Listen to changes in the delivery state
    final deliveryState = Provider.of<DeliveryState>(context, listen: false);
    deliveryState.addListener(() {
      if (deliveryState.isDeliveryStarted) {
        // Start tracking
        _startDelivery();
      } else {
        // Stop tracking
        _stopDelivery();
      }
    });
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      LocationData locationData = await location.getLocation();
      print(
          'Current Location: ${locationData.latitude}, ${locationData.longitude}');
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _subscribeToLocationChanges() {
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      print(
          'Location changed: ${currentLocation.latitude},${currentLocation.longitude}');
      //Update order tracking when location changes
      updateLocation(currentUser!.email, currentLocation.latitude ?? 0,
          currentLocation.longitude ?? 0);
      if (isDeliveryStarted) {
        updateTracking(userId, currentLocation.latitude ?? 0,
            currentLocation.longitude ?? 0);
      }
    });
    location.enableBackgroundMode(enable: true);
  }

  void _startDelivery() {
    setState(() {
      isDeliveryStarted = true;
    });
  }

  void _start() {
    setState(() {
      isActive = true;
    });
    if (isActive) {
      _subscribeToLocationChanges();
      addDriver(currentUser!.email, userLatitude, userLongitude);
      // setStatus(currentUser, 'active');
    }
  }

  void _stopDelivery() {
    setState(() {
      isDeliveryStarted = false;
    });
    if (!isDeliveryStarted) {
      setStatus(currentUser, 'completed');
    }
  }

  void _stop() {
    setState(() {
      isActive = false;
    });
    if (!isDeliveryStarted) {
      _stopTracking();
      setActiveness(currentUser, 'inactive');
    }
  }

  void _stopTracking() {
    if (locationSubscription != null) {
      locationSubscription!.cancel();
      locationSubscription = null;
    }
  }

  Future<void> addTracking(
      String email, double currentlatitude, double currentlongitude) async {
    try {
      await trackingCollection.doc(email).set({
        'email': email,
        'latitude': currentlatitude,
        'longitude': currentlongitude,
        'driver':
            currentUser!.email, // Add 'driver' field with current user's email
        'status': 'ongoing'
      });
    } catch (e) {
      print('Error adding tracking information: $e');
    }
  }

  Future<void> addDriver(
      String? email, double currentlatitude, double currentlongitude) async {
    try {
      await driverCollection.doc(email).set({
        'email': email,
        'latitude': currentlatitude,
        'longitude': currentlongitude,
        'status': 'active'
      });
    } catch (e) {
      print('Error adding tracking information: $e');
    }
  }

  Future<void> updateTracking(
      String email, double newlatitude, double newlongitude) async {
    try {
      //create/overwrite new one if new tracking is done
      await addTracking(email, newlatitude, newlongitude);
      final DocumentSnapshot trackingdoc =
          await trackingCollection.doc(email).get();
      //Check if document with this email exists
      if (trackingdoc.exists) {
        //Update
        await trackingCollection.doc(email).update({
          'latitude': newlatitude,
          'longitude': newlongitude,
        });
        print('UPDATED');
      } else {
        //Create new doc if doesnt exist
        await addTracking(email, newlatitude, newlongitude);
      }
    } catch (e) {
      print('Error adding tracking information: $e');
    }
  }

  Future<void> updateLocation(
      String? email, double newlatitude, double newlongitude) async {
    try {
      final DocumentSnapshot driverdoc =
          await driverCollection.doc(email).get();
      //Check if document with this email exists
      if (driverdoc.exists) {
        //Update
        await driverCollection.doc(email).update({
          'latitude': newlatitude,
          'longitude': newlongitude,
        });
        print('UPDATED');
      } else {
        //Create new doc if doesnt exist
        await addDriver(email, newlatitude, newlongitude);
      }
    } catch (e) {
      print('Error adding tracking information: $e');
    }
  }

  void setUserDetails(String email) async {
    await fetchUserName(email);
    await fetchUserDetails(email);
  }

  // Function to fetch user details
  Future<void> fetchUserDetails(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await getUserDetails(email);
    // Extract latitude and longitude from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        userLatitude = user['latitude'] ?? 0.0;
        userLongitude = user['longitude'] ?? 0.0;
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(
      String email) async {
    return await FirebaseFirestore.instance
        .collection("UserLocation")
        .doc(email)
        .get();
  }

  Future<void> fetchUserName(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await getUserName(email);
    // Extract username from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        username = user['username'];
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserName(
      String email) async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(email)
        .get();
  }

  Future<void> fetchUserToken(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await getUserToken(email);
    // Extract username from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        userToken = user['token'];
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserToken(
      String email) async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(email)
        .get();
  }

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exit'),
            content: const Text("Do you want to exit?"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Yes',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'No',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        bool canPop = await _onWillPop(context);
        if (canPop) {
          SystemNavigator.pop();
        } else {
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "DRIVER",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.transparent,
          actions: [
            //logout button
            IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.black))
          ],
        ),
        drawer: const MyDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              // child: TextField(
              //   controller: emailController,
              //   decoration: const InputDecoration(
              //     hintText: 'Enter user email',
              //     border: OutlineInputBorder(),
              //     filled: true,
              //     fillColor: Colors.white,
              //     hintStyle: TextStyle(color: Colors.black54),
              //     labelStyle: TextStyle(color: Colors.black),
              //   ),
              //   style: const TextStyle(color: Colors.black),
              // ),
              // ),
              // Text(
              //   username,
              //   style: const TextStyle(color: Colors.black),
              // ),
              AnimatedToggleSwitch.dual(
                current: switchValue,
                first: false,
                second: true,
                spacing: 45,
                animationDuration: const Duration(milliseconds: 600),
                style: const ToggleStyle(
                  borderColor: Colors.transparent,
                  indicatorColor: Colors.white,
                  backgroundColor: Colors.black,
                ),
                customStyleBuilder: (context, local, global) {
                  if (global.position <= 0) {
                    return ToggleStyle(backgroundColor: Colors.red[800]);
                  }
                  return ToggleStyle(
                    backgroundGradient: LinearGradient(
                      colors: [Colors.green, Colors.red[800]!],
                      stops: [
                        global.position -
                            (1 - 2 * max(0, global.position - 0.5)) * 0.7,
                        global.position +
                            max(0, 2 * (global.position - 0.5)) * 0.7,
                      ],
                    ),
                  );
                },
                borderWidth: 6,
                height: 60,
                loadingIconBuilder: (context, global) =>
                    CupertinoActivityIndicator(
                  color: Color.lerp(
                      Colors.red[800], Colors.green, global.position),
                ),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      switchValue = value;
                      if (switchValue) {
                        _start();
                      } else {
                        _stop();
                      }
                    });
                  }
                },
                iconBuilder: (value) => value
                    ? const Icon(
                        Icons.power_outlined,
                        color: Colors.green,
                        size: 32,
                      )
                    : Icon(
                        Icons.power_settings_new_rounded,
                        color: Colors.red[800],
                        size: 32,
                      ),
                textBuilder: (value) => value
                    ? const Center(
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        // if (true)
        //   Positioned(
        //     bottom: 20,
        //     left: 0.0,
        //     right: 0.0,
        //     child: Column(
        //       children: [
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             ElevatedButton(
        //               onPressed: () async {
        //                 print(userId);
        //                 if (userId != "") {
        //                   await fetchUserToken(userId);
        //                   print(userToken);
        //                 } else {
        //                   print("No User ID set");
        //                 }
        //                 notificationServices
        //                     .getDeviceToken()
        //                     .then((value) async {
        //                   var data = {
        //                     'to': userToken,
        //                     'priority': 'high',
        //                     'notification': {
        //                       'title': 'MEDEX',
        //                       'body': 'Ambulance ACCEPTED'
        //                     },
        //                     'data': {
        //                       'email': currentUser?.email,
        //                       'userType': 'user',
        //                       'context': 'accept'
        //                     },
        //                   };
        //                   await http.post(
        //                       Uri.parse(
        //                           'https://fcm.googleapis.com/fcm/send'),
        //                       body: jsonEncode(data),
        //                       headers: {
        //                         'Content-Type':
        //                             'application/json; charset=UTF-8',
        //                         'Authorization':
        //                             'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
        //                       });
        //                 });
        //               },
        //               style: ElevatedButton.styleFrom(
        //                   backgroundColor: Colors.teal,
        //                   foregroundColor: Colors.white),
        //               child: const Text('ACCEPT'),
        //             ),
        //             const SizedBox(
        //               width: 30,
        //             ),
        //             ElevatedButton(
        //               onPressed: () async {
        //                 print(userId);
        //                 if (userId != "") {
        //                   await fetchUserToken(userId);
        //                   print(userToken);
        //                 } else {
        //                   print("No User ID set");
        //                 }
        //                 notificationServices
        //                     .getDeviceToken()
        //                     .then((value) async {
        //                   var data = {
        //                     'to': userToken,
        //                     'priority': 'high',
        //                     'notification': {
        //                       'title': 'MEDEX',
        //                       'body': 'Ambulance ACCEPTED'
        //                     },
        //                     'data': {
        //                       'email': currentUser?.email,
        //                       'userType': 'user',
        //                       'context': 'accept'
        //                     },
        //                   };
        //                   await http.post(
        //                       Uri.parse(
        //                           'https://fcm.googleapis.com/fcm/send'),
        //                       body: jsonEncode(data),
        //                       headers: {
        //                         'Content-Type':
        //                             'application/json; charset=UTF-8',
        //                         'Authorization':
        //                             'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
        //                       });
        //                 });
        //               },
        //               style: ElevatedButton.styleFrom(
        //                   backgroundColor: Colors.red[600],
        //                   foregroundColor: Colors.white),
        //               child: const Text('REJECT'),
        //             ),
        //           ],
        //         ),
        // Center(
        //   child: ElevatedButton.icon(
        //     onPressed: () {
        //       launchUrl(Uri.parse(
        //           'https://www.google.com/maps?q=$userLatitude,$userLongitude'));
        //     },
        //     style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.blueAccent,
        //         foregroundColor: Colors.white),
        //     icon: const Icon(Icons.location_on),
        //     label: const Text('Show Location'),
        //   ),
        // ),
        // Center(
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       ElevatedButton(
        //         onPressed: () {
        //           _startDelivery();
        //         },
        //         child: const Text('Start Delivery'),
        //       ),
        //       const SizedBox(
        //         width: 15,
        //       ),
        //       ElevatedButton(
        //         onPressed: () {
        //           _stopDelivery();
        //         },
        //         child: const Text('Stop Delivery'),
        //       ),
        //     ],
        //   ),
        // ),
        // ],
        // ),
        // ),
      ),
    );

    // body: Padding(
    //   padding: const EdgeInsets.all(16.0),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.stretch,
    //     children: [
    //       const Text('TRACK'),
    //       const SizedBox(height: 10),
    //       TextField(
    //         controller: emailController,
    //         decoration: const InputDecoration(
    //           hintText: 'Enter user email',
    //           border: OutlineInputBorder(),
    //         ),
    //       ),
    //       const SizedBox(height: 18),
    //       ElevatedButton(
    //         onPressed: () async {
    //           if (emailController.text.isNotEmpty) {
    //             await fetchUserDetails(emailController.text);
    //             await fetchUserName(emailController.text);
    //           }
    //         },
    //         child: const Text('Search'),
    //       ),
    //       const SizedBox(height: 20),
    //       Center(
    //         child: Column(
    //           children: [
    //             Text('Customer: $username'),
    //             Text('Customer Latitude: $userLatitude'),
    //             Text('Customer Longitude: $userLongitude'),
    //           ],
    //         ),
    //       ),
    //       const SizedBox(height: 20),
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //         children: [
    //           ElevatedButton.icon(
    //             onPressed: () {
    //               launchUrl(Uri.parse(
    //                   'https://www.google.com/maps?q=$userLatitude,$userLongitude'));
    //             },
    //             style: ElevatedButton.styleFrom(
    //                 backgroundColor: Colors.blueAccent,
    //                 foregroundColor: Colors.white),
    //             icon: const Icon(Icons.location_on),
    //             label: const Text('Show Location'),
    //           ),
    //           ElevatedButton(
    //             onPressed: () {
    //               isDeliveryStarted ? null : _startDelivery();
    //             },
    //             style: ElevatedButton.styleFrom(
    //                 backgroundColor: Colors.green,
    //                 foregroundColor: Colors.white),
    //             child: const Text('Start Journey'),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 30),
    //       ElevatedButton(
    //         onPressed: () {
    //           notificationServices.getDeviceToken().then((value) async {
    //             var data = {
    //               'to': value.toString(),
    //               'priority': 'high',
    //               'notification': {
    //                 'title': 'MEDEX',
    //                 'body': value.toString()
    //               },
    //               'data': {'email': currentUser?.email},
    //             };
    //             await http.post(
    //                 Uri.parse('https://fcm.googleapis.com/fcm/send'),
    //                 body: jsonEncode(data),
    //                 headers: {
    //                   'Content-Type': 'application/json; charset=UTF-8',
    //                   'Authorization':
    //                       'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
    //                 });
    //           });
    //         },
    //         style: ElevatedButton.styleFrom(
    //             backgroundColor: Colors.red, foregroundColor: Colors.white),
    //         child: const Text('Send Notification Test'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () {
    //           isDeliveryStarted ? _stopDelivery() : null;
    //         },
    //         style: ElevatedButton.styleFrom(
    //             backgroundColor: Colors.red, foregroundColor: Colors.white),
    //         child: const Text('Stop Journey'),
    //       ),
    //     ],
    //   ),
    // ),
  }

  Future<void> setToken(User? currentUser, String token) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .update({
        'token': token,
      });
    }
  }

  Future<void> setActiveness(User? currentUser, String status) async {
    if (currentUser != null) {
      print("Status $status Set");
      await FirebaseFirestore.instance
          .collection("DriverLocation")
          .doc(currentUser.email)
          .update({
        'status': status,
      });
    }
  }

  Future<void> setStatus(User? currentUser, String status) async {
    if (currentUser != null) {
      print("TrackingStatus $status Set");
      await FirebaseFirestore.instance
          .collection("Tracking")
          .doc(userId)
          .update({
        'status': status,
      });
    }
  }
}
