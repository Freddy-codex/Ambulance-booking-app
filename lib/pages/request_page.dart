import 'dart:async';
import 'dart:convert';

import 'package:ambulance/services/constants.dart';
import 'package:ambulance/services/delivery_state.dart';
import 'package:ambulance/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class RequestPage extends StatefulWidget {
  const RequestPage({
    super.key,
    required this.userId,
    required this.username,
    required this.userLatitude,
    required this.userLongitude,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.usernumber,
  });
  final String userId;
  final String username;
  final double userLatitude;
  final double userLongitude;
  final double driverLatitude;
  final double driverLongitude;
  final String usernumber;

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  late double userLatitude;
  late double userLongitude;
  late double driverLatitude;
  late double driverLongitude;
  String username = "";
  // String userId = "";
  String userToken = "";
  double distance = 0.0;
  bool isStarted = false;
  GoogleMapController? mapController;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationServices notificationServices =
      NotificationServices.instance;
  StreamSubscription<LocationData>? locationSubscription;
  Map<PolylineId, Polyline> polylines = {};

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference userCollection;
  late CollectionReference userLocationCollection;
  late CollectionReference driverCollection;
  late CollectionReference trackingCollection;
  late LatLng _selectedLocation;

  @override
  void initState() {
    trackingCollection = firestore.collection('Tracking');

    super.initState();
    _selectedLocation = LatLng(widget.userLatitude, widget.userLongitude);
    userLatitude = widget.userLatitude;
    userLongitude = widget.userLongitude;
    driverLatitude = widget.driverLatitude;
    driverLongitude = widget.driverLongitude;
    calculateDistance();
  }

  void calculateDistance() {
    double dist = Geolocator.distanceBetween(
      driverLatitude,
      driverLongitude,
      userLatitude,
      userLongitude,
    );
    // Convert meters into kilometers
    double distanceInKm = dist / 1000;
    setState(() {
      distance = distanceInKm;
    });
    print('Distance: ${distance}');
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
        mapsAPIKey,
        PointLatLng(widget.driverLatitude, widget.driverLongitude),
        PointLatLng(
          widget.userLatitude,
          widget.userLongitude,
        ));
    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolylineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');
    final polyline = Polyline(
      polylineId: id,
      color: const Color.fromARGB(255, 10, 80, 202),
      points: polylineCoordinates,
      width: 8,
    );
    setState(() => polylines[id] = polyline);
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "AMBULANCE REQUEST",
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.black,
        ),
        body: Stack(
          children: [
            GoogleMap(
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.terrain,
              onMapCreated: (controller) async {
                mapController = controller;
                final coordinates = await fetchPolylinePoints();
                generatePolylineFromPoints(coordinates);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: _selectedLocation,
                  infoWindow: InfoWindow(
                    title: 'Selected Location',
                    snippet:
                        'Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}',
                  ),
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.userLatitude, widget.userLongitude),
                zoom: 12,
              ),
              myLocationEnabled: true,
              compassEnabled: false,
            ),
            Positioned(
              left: 20.0,
              right: 20.0,
              top: 150.0,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                    color: const Color(0xff1d1d1d),
                    borderRadius: BorderRadius.circular(38.0),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 5,
                      )
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.username,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            "${distance.toStringAsFixed(2)} km",
                            style: GoogleFonts.poppins(
                              fontSize: 27,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 13,
                          ),
                          Text(
                            '+91 ${widget.usernumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          )
                        ],
                      ),
                      Positioned(
                        bottom: 18,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri url = Uri(
                                  scheme: 'tel',
                                  path: '+91${widget.usernumber}',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  print('Cannot Launch URL');
                                }
                              },
                              icon: const Icon(Icons.call),
                              label: Text(
                                'Call',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0c8a0c),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isStarted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarGlow(
                      glowColor: const Color.fromARGB(255, 5, 156, 0),
                      glowRadiusFactor: 1.0,
                      child: ElevatedButton(
                        onPressed: () async {
                          print(widget.userId);
                          if (widget.userId != "") {
                            await fetchUserToken(widget.userId);
                            print(userToken);
                          } else {
                            print("No User ID set");
                          }
                          notificationServices
                              .getDeviceToken()
                              .then((value) async {
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
                                Uri.parse(
                                    'https://fcm.googleapis.com/fcm/send'),
                                body: jsonEncode(data),
                                headers: {
                                  'Content-Type':
                                      'application/json; charset=UTF-8',
                                  'Authorization': 'key=$messagingAPIKey'
                                });
                          });
                          deliveryState.startDelivery();
                          launchUrl(Uri.parse(
                              'https://www.google.com/maps?q=$userLatitude,$userLongitude'));
                          setState(() {
                            isStarted = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0c8a0c),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Accept',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    AvatarGlow(
                      glowColor: const Color.fromARGB(255, 158, 0, 0),
                      glowRadiusFactor: 1.0,
                      child: ElevatedButton(
                        onPressed: () async {
                          print(widget.userId);
                          if (widget.userId != "") {
                            await fetchUserToken(widget.userId);
                            print(userToken);
                          } else {
                            print("No User ID set");
                          }
                          notificationServices
                              .getDeviceToken()
                              .then((value) async {
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
                                Uri.parse(
                                    'https://fcm.googleapis.com/fcm/send'),
                                body: jsonEncode(data),
                                headers: {
                                  'Content-Type':
                                      'application/json; charset=UTF-8',
                                  'Authorization': 'key=$messagingAPIKey'
                                });
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isStarted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        deliveryState.stopDelivery();
                        setStatus(currentUser, 'completed');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 30,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        child: Text(
                          'Arrived at Hospital',
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
