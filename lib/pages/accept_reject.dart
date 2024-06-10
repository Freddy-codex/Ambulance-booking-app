import 'dart:async';
import 'dart:convert';
// import 'dart:io';
// import 'dart:math';

import 'package:ambulance/components/drawer.dart';
import 'package:ambulance/pages/delivery_state.dart';
import 'package:ambulance/pages/notification_services.dart';
// import 'package:animated_toggle_switch/animated_toggle_switch.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AcceptReject extends StatefulWidget {
  const AcceptReject({super.key, required this.userId});
  final String userId;

  @override
  State<AcceptReject> createState() => _AcceptRejectState();
}

class _AcceptRejectState extends State<AcceptReject> {
  double userLatitude = 0.0;
  double userLongitude = 0.0;
  String username = "";
  // String userId = "";
  String userToken = "";
  bool isDeliveryStarted = false;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationServices notificationServices =
      NotificationServices.instance;
  StreamSubscription<LocationData>? locationSubscription;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference userCollection;
  late CollectionReference userLocationCollection;
  late CollectionReference driverCollection;
  late CollectionReference trackingCollection;

  @override
  void initState() {
    trackingCollection = firestore.collection('Tracking');
    // driverCollection = firestore.collection('DriverLocation');
    super.initState();
  }

  // void _startDelivery() {
  //   setState(() {
  //     isDeliveryStarted = true;
  //   });
  // }

  // void _stopDelivery() {
  //   setState(() {
  //     isDeliveryStarted = false;
  //   });
  //   if (!isDeliveryStarted) {
  //     setStatus(currentUser, 'completed');
  //   }
  // }

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
    final deliveryState = Provider.of<DeliveryState>(context);
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
            "HELP",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.transparent,
        ),
        drawer: const MyDrawer(),
        body: Column(
          children: [
            Text(
              username,
              style: const TextStyle(color: Colors.black),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    print(widget.userId);
                    if (widget.userId != "") {
                      await fetchUserToken(widget.userId);
                      print(userToken);
                    } else {
                      print("No User ID set");
                    }
                    notificationServices.getDeviceToken().then((value) async {
                      var data = {
                        'to': userToken,
                        'priority': 'high',
                        'notification': {
                          'title': 'MEDEX',
                          'body': 'Ambulance ACCEPTED'
                        },
                        'data': {
                          'email': currentUser?.email,
                          'userType': 'user',
                          'context': 'accept'
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
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                  child: const Text('ACCEPT'),
                ),
                const SizedBox(
                  width: 30,
                ),
                ElevatedButton(
                  onPressed: () async {
                    print(widget.userId);
                    if (widget.userId != "") {
                      await fetchUserToken(widget.userId);
                      print(userToken);
                    } else {
                      print("No User ID set");
                    }
                    notificationServices.getDeviceToken().then((value) async {
                      var data = {
                        'to': userToken,
                        'priority': 'high',
                        'notification': {
                          'title': 'MEDEX',
                          'body': 'Ambulance REJECTED'
                        },
                        'data': {
                          'email': currentUser?.email,
                          'userType': 'user',
                          'context': 'reject'
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
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white),
                  child: const Text('REJECT'),
                ),
              ],
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse(
                      'https://www.google.com/maps?q=$userLatitude,$userLongitude'));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.location_on),
                label: const Text('Show Location'),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      deliveryState.startDelivery();
                    },
                    child: const Text('Start Delivery'),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      deliveryState.stopDelivery();
                      setStatus(currentUser, 'completed');
                      Navigator.pop(context);
                    },
                    child: const Text('Stop Delivery'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> setStatus(User? currentUser, String status) async {
    if (currentUser != null) {
      print("TrackingStatus $status Set");
      await FirebaseFirestore.instance
          .collection("Tracking")
          .doc(widget.userId)
          .update({
        'status': status,
      });
    }
  }
}
