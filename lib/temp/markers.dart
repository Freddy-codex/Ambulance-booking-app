import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  final List<Marker> _markers = [];
  LatLng destination = const LatLng(10.1760439, 76.4449);
  String selectedMarkerId = 'default';
  String nearestDriver = '';
  double nearestDistance = -1;
  LatLng nearestLocation = const LatLng(0, 0);
  BitmapDescriptor markerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

  @override
  void initState() {
    super.initState();
    addCustomMarker();
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      updateDestinationLocation(email);
    }
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
          infoWindow: InfoWindow(
              title: document.id,
              snippet: '${distance.toStringAsFixed(2)} KM',
              onTap: () {
                setState(() {
                  selectedMarkerId = document.id;
                });
                _showBottomSheet(context, document.id);
              }),
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

  String getDriverId() {
    return selectedMarkerId;
  }

  void _showBottomSheet(BuildContext context, String markerId) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Marker ID: $markerId'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedMarkerId = markerId;
                      });
                      Navigator.pop(context);
                      Navigator.pop(context, selectedMarkerId);
                      print(selectedMarkerId);

                      DelightToastBar(
                        builder: (context) {
                          return const ToastCard(
                            color: Colors.black,
                            leading: Icon(
                              Icons.check_circle_rounded,
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
                        snackbarDuration: Duration(seconds: 2),
                      ).show(context);
                    },
                    child: const Text(
                      'Select Ambulance',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff1d1d1d)),
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
      appBar: AppBar(
        title: const Text('Available Ambulances'),
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
        ),
        // Padding(
        //   padding: const EdgeInsets.only(top: 550),
        //   child: Container(
        //     decoration: const BoxDecoration(
        //       boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
        //       borderRadius: BorderRadius.only(
        //           topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        //       color: Colors.white,
        //     ),
        //     height: double.infinity,
        //     width: double.infinity,
        //   ),
        // ),
        Positioned(
          top: 2.0,
          left: 60.0,
          right: 60.0,
          child: ElevatedButton.icon(
            onPressed: () {
              _controller
                  .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(target: nearestLocation, zoom: 18.0)))
                  .then((_) {
                _controller.showMarkerInfoWindow(MarkerId(nearestDriver));
              });
            },
            icon: const Icon(
              Icons.location_searching_rounded,
              color: Colors.red,
            ),
            label: const Text('Show Nearest Ambulance'),
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
