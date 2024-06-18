import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackAmbulance extends StatefulWidget {
  const TrackAmbulance(
      {super.key, required this.number, required this.drivername});
  final String drivername;
  final String number;

  @override
  State<TrackAmbulance> createState() => _TrackAmbulanceState();
}

class _TrackAmbulanceState extends State<TrackAmbulance> {
  LatLng destination = const LatLng(10.1760439, 76.4449);
  LatLng driverLocation = const LatLng(10.15706, 76.4463702);
  Map<PolylineId, Polyline> polylines = {};
  GoogleMapController? mapcontroller;
  // User? currentUser = FirebaseAuth.instance.currentUser;
  BitmapDescriptor markerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  double remainingDistance = 0.0;
  Timer? trackingTimer;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference trackingCollection;

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

  void updateCurrentLocation(LatLng destination) {
    setState(() {
      this.destination = destination;
    });
  }

  void calculateRemainingDistance() {
    double distance = Geolocator.distanceBetween(
      driverLocation.latitude,
      driverLocation.longitude,
      destination.latitude,
      destination.longitude,
    );
    // Convert meters into kilometers
    double distanceInKm = distance / 1000;
    setState(() {
      remainingDistance = distanceInKm;
    });
    print('Remaining distance: ${remainingDistance}');
  }

  Timer startTracking(String email) {
    return Timer.periodic(const Duration(seconds: 1), (timer) async {
      var trackingData = await getOrderTracking(email);
      if (trackingData != null) {
        double latitude = trackingData['latitude'];
        double longitude = trackingData['longitude'];
        if (trackingData['status'] == "completed") {
          Navigator.pop(context);
          Navigator.pop(context);
          trackingCollection.doc(email).delete();
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'HOSPITAL REACHED',
            text: 'Thankyou for using MedEx',
            barrierDismissible: false,
            disableBackBtn: true,
          );
        }
        updateUIWithLocation(latitude, longitude);
        print('Latest Location: $latitude , $longitude');
      } else {
        print('No tracking data available for: $email');
      }
    });
  }

  Future<Map<String, dynamic>?> getOrderTracking(String email) async {
    try {
      var snapshot = await trackingCollection.doc(email).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving tracking information: $e');
      return null;
    }
  }

  void updateUIWithLocation(double latitude, double longitude) async {
    setState(() {
      driverLocation = LatLng(latitude, longitude);
    });
    final coordinates = await fetchPolylinePoints();
    generatePolylineFromPoints(coordinates);
    //update camera position to a new location
    mapcontroller?.animateCamera(CameraUpdate.newLatLng(driverLocation));
    //calculate remaining distance
    calculateRemainingDistance();
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyASOtAOhPLYKwr9KF-X2h9WatIxNLHWt8s',
      PointLatLng(driverLocation.latitude, driverLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
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

  void updateDestinationLocation(String email) async {
    await fetchLocation(email);
    updateCurrentLocation(destination);
  }

  @override
  void initState() {
    super.initState();
    trackingCollection = firestore.collection('Tracking');
    addCustomMarker();
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      trackingTimer = startTracking(email);
    }
    updateDestinationLocation(email!);
  }

  @override
  void dispose() {
    super.dispose();
    trackingTimer?.cancel(); // Cancel the timer when the widget is disposed
    trackingTimer = null;
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
          title: Text(
            'AMBULANCE TRACKING',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              initialCameraPosition: CameraPosition(
                target: driverLocation,
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: 'Destination',
                    snippet:
                        'Lat: ${destination.latitude}, Lng: ${destination.longitude}',
                  ),
                ),
                Marker(
                  markerId: const MarkerId('driverlocation'),
                  position: driverLocation,
                  icon: markerIcon,
                  infoWindow: InfoWindow(
                    title: 'Driver Location',
                    snippet:
                        'Lat: ${driverLocation.latitude}, Lng: ${driverLocation.longitude}',
                  ),
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
            Positioned(
              top: 16.0,
              left: 0.0,
              right: 0.0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 201, 5, 5),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Text(
                    "Remaining Distance:  ${remainingDistance.toStringAsFixed(2)}km",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20.0,
              right: 20.0,
              bottom: 40.0,
              child: Container(
                height: 110,
                // padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                    color: const Color(0xff1d1d1d),
                    borderRadius: BorderRadius.circular(27.0),
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
                            widget.drivername,
                            style: GoogleFonts.poppins(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 6.5,
                          ),
                          Text(
                            '+91 ${widget.number}',
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
                        bottom: 9,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri url = Uri(
                                  scheme: 'tel',
                                  path: '+91${widget.number}',
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
            )
          ],
        ),
      ),
    );
  }
}
