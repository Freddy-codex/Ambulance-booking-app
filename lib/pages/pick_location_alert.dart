import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerAlert extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;

  const LocationPickerAlert({super.key, this.onLocationSelected});

  @override
  LocationPickerAlertState createState() => LocationPickerAlertState();
}

class LocationPickerAlertState extends State<LocationPickerAlert> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  GoogleMapController? mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  void _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      //Handle case where permission is denied
      print('Location permission denied');
    } else if (permission == LocationPermission.deniedForever) {
      //Handle case where permission is denied permanently
      print('Location permission denied forever');
    } else {
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                mapType: MapType.terrain,
                onMapCreated: (controller) {
                  mapController = controller;
                },
                onTap: (latLng) {
                  setState(() {
                    _selectedLocation = latLng;
                  });
                },
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('selectedLocation'),
                          position: _selectedLocation!,
                          infoWindow: InfoWindow(
                            title: 'Selected Location',
                            snippet:
                                'Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}',
                          ),
                        ),
                      }
                    : {},
                initialCameraPosition: const CameraPosition(
                  target: LatLng(10.15, 76.42),
                  zoom: 10,
                ),
                myLocationEnabled: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 5),
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () async {
                  if (_selectedLocation != null) {
                    print(
                        'Selected Location - Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}');
                    createUserDocument(currentUser);
                    Navigator.pop(context);
                    widget.onLocationSelected?.call(_selectedLocation!);
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text("Ambulance Selected"),
                    //     duration: Duration(seconds: 2),
                    //   ),
                    // );
                    DelightToastBar(
                      builder: (context) {
                        return const ToastCard(
                          leading: Icon(
                            Icons.location_on_sharp,
                            size: 32,
                          ),
                          title: Text(
                            "Pickup Location Selected",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                      position: DelightSnackbarPosition.top,
                      autoDismiss: true,
                      snackbarDuration: const Duration(seconds: 2),
                    ).show(context);
                  } else {
                    //Handle case when no loction is selected
                  }
                },
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createUserDocument(User? currentUser) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection("UserLocation")
          .doc(currentUser.email)
          .set({
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
      });
    }
  }
}
