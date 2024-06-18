import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ambulance/components/drawer.dart';
import 'package:ambulance/temp/markers.dart';
import 'package:ambulance/services/notification_services.dart';
import 'package:ambulance/temp/pick_location_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationServices notificationServices =
      NotificationServices.instance;
  // StreamSubscription<RemoteMessage>? _onMessageSubscription;

  User? currentUser = FirebaseAuth.instance.currentUser;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference userCollection;
  LatLng? selectedLocation;
  String driverid = "";
  String drivertoken = "";
  String username = "";
  bool _initialized = false;
  // bool showButton = false;

  @override
  void initState() {
    // TODO: implement initState
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

    // FirebaseMessaging.onMessage.listen((message) {
    //   if (kDebugMode) {
    //     print(message.notification!.title.toString());
    //     print(message.notification?.body.toString());
    //     print('Message Data: ${message.data}');
    //     // print(message.data['email'].toString());
    //   }
    //   if (Platform.isAndroid) {
    //     notificationServices.initLocalNotifications(context, message);
    //     notificationServices.showNotification(message);
    //   }
    //   if (message.data['context'] == 'accept') {
    //     Navigator.pop(context); // Close the dialog
    //     QuickAlert.show(
    //       context: context,
    //       type: QuickAlertType.success,
    //       title: 'AMBULANCE ACCEPTED',
    //       text: 'Ambulance is on the way...',
    //       barrierDismissible: false,
    //       disableBackBtn: true,
    //     );
    //   }
    //   if (message.data['context'] == 'reject') {
    //     Navigator.pop(context); // Close the dialog
    //     QuickAlert.show(
    //       context: context,
    //       type: QuickAlertType.error,
    //       title: 'AMBULANCE REJECTED',
    //       text: 'Please Try another ambulance',
    //       barrierDismissible: false,
    //       disableBackBtn: true,
    //     );
    //   }
    // });

    // notificationServices.setupInteractMessage(context);
  }

  Future<String?> navigateToMapScreen() async {
    return await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  Future<void> fetchDriverToken(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await getDriverToken(email);
    // Extract username from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        drivertoken = user['token'];
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDriverToken(
      String email) async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(email)
        .get();
  }

  Future<void> fetchUserName(String? email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await getUserName(email!);
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

  //logout function
  void logout() {
    FirebaseAuth.instance.signOut();
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
    userCollection = firestore.collection('UserLocation');
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
              "Home",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.deepPurple,
            actions: [
              //logout button
              IconButton(
                  onPressed: logout,
                  icon: const Icon(Icons.logout, color: Colors.white))
            ],
          ),
          drawer: const MyDrawer(),
          body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return LocationPickerAlert(
                        onLocationSelected: (LatLng userLocation) {
                          selectedLocation = userLocation;
                          print(
                              "Selected Location - Lat: ${userLocation.latitude} Lng: ${userLocation.longitude}");
                        },
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  // primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.location_on),
                label: const Text('Select location from Map'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  String? selectedMarkerId = await navigateToMapScreen();
                  // Handle the selectedMarkerId returned from the MapScreen
                  print(selectedMarkerId);
                  setState(() {
                    driverid = selectedMarkerId!;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  // primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.manage_search),
                label: const Text('Search Ambulances'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  print(driverid);
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.loading,
                    title: 'Waiting for Confirmation',
                    text: 'Please don\'t close the App',
                    barrierDismissible: false,
                    disableBackBtn: true,
                    // autoCloseDuration: Duration(seconds: 5),
                  );

                  if (driverid != "") {
                    await fetchDriverToken(driverid);
                    await fetchUserName(currentUser?.email);
                    print(drivertoken);
                  } else {
                    print("No Driver ID set");
                  }
                  notificationServices.getDeviceToken().then((value) async {
                    var data = {
                      'to': drivertoken,
                      'priority': 'high',
                      'notification': {
                        'title': 'MEDEX',
                        'body': 'Ambulance REQUEST from $username'
                      },
                      'data': {
                        'email': currentUser?.email,
                        'userType': 'driver',
                      },
                    };
                    await http.post(
                        Uri.parse('https://fcm.googleapis.com/fcm/send'),
                        body: jsonEncode(data),
                        headers: {
                          'Content-Type': 'application/json; charset=UTF-8',
                          'Authorization':
                              'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
                        });
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(CupertinoIcons.plus_circle),
                label: const Text('Request Ambulance'),
              ),
              TextButton(
                onPressed: () {
                  notificationServices.getDeviceToken().then((value) async {
                    var data = {
                      'to': value.toString(),
                      'priority': 'high',
                      'notification': {
                        'title': 'LOCAL TEST',
                        'body': 'Please work'
                      },
                      'data': {
                        'userType': 'user',
                      },
                    };
                    await http.post(
                        Uri.parse('https://fcm.googleapis.com/fcm/send'),
                        body: jsonEncode(data),
                        headers: {
                          'Content-Type': 'application/json; charset=UTF-8',
                          'Authorization':
                              'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
                        });
                  });
                },
                child: const Text(
                  "Send Local Notification",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  //  Navigator.pop(context);
                  Navigator.pushNamed(context, 'trackingpage');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  // primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.location_searching),
                label: const Text('TRACK'),
              ),
            ]),
          )),
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
}
