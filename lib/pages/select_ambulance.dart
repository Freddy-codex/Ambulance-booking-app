import 'dart:convert';
import 'dart:io';

import 'package:ambulance/services/constants.dart';
import 'package:ambulance/services/notification_services.dart';
import 'package:ambulance/pages/track_ambulance.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:http/http.dart' as http;

class SelectAmbulance extends StatefulWidget {
  const SelectAmbulance({super.key});

  @override
  _SelectAmbulanceState createState() => _SelectAmbulanceState();
}

class _SelectAmbulanceState extends State<SelectAmbulance> {
  late GoogleMapController _controller;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final List<Marker> _markers = [];
  LatLng destination = const LatLng(10.1760439, 76.4449);
  String nearestDriver = '';
  double nearestDistance = -1;
  LatLng nearestLocation = const LatLng(0, 0);
  String driverid = 'default';
  String drivertoken = "";
  String driver = '';
  String username = "";
  String userphone = "";
  BitmapDescriptor markerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  final NotificationServices notificationServices =
      NotificationServices.instance;

  @override
  void initState() {
    super.initState();
    addCustomMarker();
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      updateDestinationLocation(email);
    }
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification?.body.toString());
        print('Message Data: ${message.data}');
        // print(message.data['email'].toString());
      }
      if (Platform.isAndroid) {
        notificationServices.initLocalNotifications(context, message);
        notificationServices.showNotification(message);
      }
      if (message.data['context'] == 'accept') {
        Navigator.pop(context); // Close the dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackAmbulance(
              number: userphone,
              drivername: driver,
            ),
          ),
        );
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'AMBULANCE ACCEPTED',
          text: 'Ambulance is on the way...',
          barrierDismissible: false,
          disableBackBtn: true,
        );
      }
      if (message.data['context'] == 'reject') {
        Navigator.pop(context); // Close the dialog
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'AMBULANCE REJECTED',
          text: 'Please Try another ambulance',
          barrierDismissible: false,
          disableBackBtn: true,
        );
      }
    });

    notificationServices.setupInteractMessage(context);
  }

  void addCustomMarker() {
    ImageConfiguration configuration =
        const ImageConfiguration(size: Size(0, 0)); // Set the desired size here
    BitmapDescriptor.fromAssetImage(configuration, 'assets/marker4.png',
            mipmaps: false) // Add mipmaps: false
        .then((value) {
      setState(() {
        markerIcon = value;
      });
    });
  }

  Future<void> updateDestinationLocation(String email) async {
    await fetchLocation(email);
    await _fetchDriverLocations();
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'YOU',
          snippet:
              'Lat: ${destination.latitude}, Lng: ${destination.longitude}',
        ),
      ));
    });
  }

  Future<void> fetchLocation(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await getSelectedLocation(email);
    // Extract latitude and longitude from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        destination = LatLng(user['latitude'], user['longitude']);
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSelectedLocation(
      String email) async {
    return await FirebaseFirestore.instance
        .collection("UserLocation")
        .doc(email)
        .get();
  }

  Future<void> _fetchDriverLocations() async {
    try {
      // Fetch driver locations from Firestore
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('DriverLocation').get();

      // Clear previous markers
      _markers.removeWhere((marker) => marker.markerId.value != 'destination');

      // Add markers for each driver location
      for (var document in querySnapshot.docs) {
        // if (document['status'] == 'active') {
        double latitude = document['latitude'];
        double longitude = document['longitude'];
        // String driverName = document['name'];
        print(document.id);
        print(
            'latitude: ${document['latitude']}, longitude: ,${document['longitude']}');
        double distance = calculateDriverDistance(LatLng(latitude, longitude));
        if (distance < nearestDistance || nearestDistance < 0) {
          setState(() {
            nearestDistance = distance;
            nearestDriver = document.id;
            nearestLocation = LatLng(latitude, longitude);
          });
        }
        // Create a marker
        Marker marker = Marker(
          markerId: MarkerId(document.id),
          position: LatLng(latitude, longitude),
          onTap: () {
            setState(() {
              driverid = document.id;
            });
            _showBottomSheet(context, document.id, distance.toStringAsFixed(2));
          },
          // infoWindow: InfoWindow(
          //     title: document.id,
          //     snippet: '${distance.toStringAsFixed(2)} KM',
          //     onTap: () {
          //       setState(() {
          //         driverid = document.id;
          //       });
          //       _showBottomSheet(context, document.id);
          //     }),
          // You can customize the marker icon here
          icon: markerIcon,
        );

        // Add marker to the list
        _markers.add(marker);
        // }
      }

      // Update the UI
      setState(() {});
    } catch (e) {
      print('Error fetching driver locations: $e');
    }
  }

  double calculateDriverDistance(LatLng driverLocation) {
    double distance = Geolocator.distanceBetween(
      driverLocation.latitude,
      driverLocation.longitude,
      destination.latitude,
      destination.longitude,
    );
    // Convert meters into kilometers
    double distanceInKm = distance / 1000;
    return distanceInKm;
  }

  Future<void> fetchDriverToken(String email) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await getDriverToken(email);
    // Extract username from snapshot data
    Map<String, dynamic>? user = snapshot.data();
    if (user != null) {
      setState(() {
        drivertoken = user['token'];
        driver = user['username'];
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
        userphone = user['number'];
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

  String getDriverId() {
    return driverid;
  }

  void _showBottomSheet(
      BuildContext context, String markerId, String distance) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xff1d1d1d),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$distance km',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        driverid = markerId;
                      });
                      print(driverid);
                      Navigator.pop(context);
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
                              'Authorization': 'key=$messagingAPIKey'
                            });
                      });
                      DelightToastBar(
                        builder: (context) {
                          return const ToastCard(
                            color: Colors.black,
                            leading: Icon(
                              Icons.check_circle_outline,
                              size: 32,
                              color: Colors.green,
                            ),
                            title: Text(
                              "Ambulance Selected",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          );
                        },
                        position: DelightSnackbarPosition.top,
                        autoDismiss: true,
                        snackbarDuration: const Duration(seconds: 2),
                      ).show(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1d1d1d),
                        side: const BorderSide(color: Color(0xff1166cc))),
                    child: const Text(
                      'Confirm Ambulance',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'AVAILABLE AMBULANCES',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: const CameraPosition(
            target: LatLng(10.153337241852883,
                76.46088548004627), // Initial position of the map
            zoom: 10.0, // Zoom level of the map
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          markers: Set<Marker>.of(_markers),
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          bottom: 40.0,
          left: 30.0,
          right: 30.0,
          child: ElevatedButton.icon(
            onPressed: () {
              _controller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: nearestLocation, zoom: 18.0)));
            },
            icon: const Icon(
              Icons.my_location,
              color: Colors.red,
            ),
            label: const Text(
              'Show Nearest Ambulance',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ]),
    );
  }
}
