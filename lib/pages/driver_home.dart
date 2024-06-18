import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ambulance/services/delivery_state.dart';
import 'package:ambulance/services/notification_services.dart';
import 'package:ambulance/pages/profile_page.dart';
import 'package:ambulance/pages/request_page.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool switchValue = false;
  // bool showButton = false;

  Location location = Location();
  double userLatitude = 0.0;
  double userLongitude = 0.0;
  double driverLatitude = 0.0;
  double driverLongitude = 0.0;
  String username = "";
  String userId = "";
  String usernumber = "";
  String userToken = "";
  bool isDeliveryStarted = false;
  bool isActive = false;
  bool isnewTracking = false;
  bool _initialized = false;
  User? currentUser = FirebaseAuth.instance.currentUser;
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
    notificationServices.setupInteractMessage(context);
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
    });

    notificationServices.setupInteractMessage(context);

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
      setState(() {
        driverLatitude = locationData.latitude!;
        driverLongitude = locationData.longitude!;
      });
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
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RequestPage(
                  userId: email,
                  username: username,
                  usernumber: usernumber,
                  userLatitude: userLatitude,
                  userLongitude: userLongitude,
                  driverLatitude: driverLatitude,
                  driverLongitude: driverLongitude,
                )));
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
        usernumber = user['number'];
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
    // SystemChrome.setSystemUIOverlayStyle(
    //     const SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
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
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              "DRIVER",
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.black,
            leading: IconButton(
                onPressed: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) => ProfilePage()));
                },
                icon: const Icon(Icons.person, color: Colors.white)),
            actions: [
              //logout button
              IconButton(
                  onPressed: logout,
                  icon: const Icon(Icons.logout, color: Colors.white))
            ],
          ),
          backgroundColor: const Color(0xff1d1d1d),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                          Icons.local_hospital,
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
        ),
      ),
    );
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
