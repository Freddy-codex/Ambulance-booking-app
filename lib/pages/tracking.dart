import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Tracking'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
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
          // Positioned.fill(
          //     child: Align(alignment: Alignment.center, child: _getMarker())),
          Positioned(
            top: 16.0,
            left: 0.0,
            right: 0.0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  "Remaining Distance: ${remainingDistance.toStringAsFixed(2)} KM",
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ),
          ),
          Positioned(
              left: 90.0,
              right: 90.0,
              bottom: 30.0,
              child: ElevatedButton.icon(
                onPressed: () {
                  trackingTimer?.cancel();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                label: const Text('STOP TRACKING'),
                icon: const Icon(Icons.wrong_location),
              )),
        ],
      ),
    );
  }
}
