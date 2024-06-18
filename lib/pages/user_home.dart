import 'package:ambulance/services/notification_services.dart';
import 'package:ambulance/pages/select_ambulance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  GoogleMapController? mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  final NotificationServices notificationServices =
      NotificationServices.instance;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    notificationServices.getDeviceToken().then((value) {
      print('Device Token:');
      print(value);
      setToken(currentUser, value);
    });
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
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _panToCurrentLocation() {
    if (_currentLocation != null && mapController != null) {
      setState(() {
        _selectedLocation = _currentLocation;
      });
      mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 15));
    } else {
      print('Current location or map controller is not available.');
    }
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
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //     statusBarColor: Colors.cyan, systemNavigationBarColor: Colors.amber));
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              "SELECT LOCATION",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.black,
          ),
          body: Stack(
            children: [
              GoogleMap(
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
                myLocationEnabled: false,
                compassEnabled: false,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.transparent,
                    ],
                    begin: Alignment(0.0, -0.8),
                    end: Alignment.bottomCenter,
                  ),
                ),
                width: double.infinity,
                height: 160,
              ),
              // Positioned(
              //   top: 120,
              //   left: 15,
              //   right: 15,
              //   child: Column(
              //     children: [
              //       TextField(
              //         controller: searchController,
              //         decoration: InputDecoration(
              //           hintText: 'Search location',
              //           filled: true,
              //           fillColor: Colors.white,
              //           border: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(10),
              //             borderSide: BorderSide.none,
              //           ),
              //           prefixIcon: Icon(Icons.search),
              //         ),
              //         onChanged: (value) {
              //           if (value.isNotEmpty) {}
              //         },
              //       ),
              //       // if (predictions.isNotEmpty)
              //     ],
              //   ),
              // ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40)),
                    color: Color(0xff1d1d1d),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedLocation != null) {
                            print(
                                'Selected Location - Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}');
                            createUserDocument(currentUser);
                            DelightToastBar(
                              builder: (context) {
                                return const ToastCard(
                                  color: Colors.black,
                                  leading: Icon(
                                    Icons.location_on_sharp,
                                    size: 32,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    "Pickup Location Selected",
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
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelectAmbulance(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1d1d1d),
                            side: const BorderSide(color: Color(0xff1166cc))),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                              fontSize: 21,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 110.0, left: 14),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black, // Background color of the container
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'profilepage');
                    },
                    iconSize: 30,
                    icon: const Icon(Icons.person),
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 125,
                right: 17,
                child: FloatingActionButton(
                  onPressed: _panToCurrentLocation,
                  backgroundColor: const Color(0xff1d1d1d),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
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
