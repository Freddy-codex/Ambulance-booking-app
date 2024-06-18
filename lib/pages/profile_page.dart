import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  //current logged user
  User? currentUser = FirebaseAuth.instance.currentUser;

  //to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "PROFILE",
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white70,
      ),
      backgroundColor: const Color.fromARGB(255, 26, 25, 25),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          //loading..
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          //error
          else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }

          //data recieved
          else if (snapshot.hasData) {
            //extract data
            Map<String, dynamic>? user = snapshot.data!.data();
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Text(user?['username'],
                    //     style: const TextStyle(
                    //       fontSize: 15,
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                    // Text(user?['email'],
                    //     style: const TextStyle(
                    //       fontSize: 15,
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                    // Text(user?['number'],
                    //     style: const TextStyle(
                    //       fontSize: 15,
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                    // if (user?['type'] == 'driver')
                    //   Text(user?['vehicle'],
                    //       style: const TextStyle(
                    //         fontSize: 15,
                    //         color: Colors.white,
                    //         fontWeight: FontWeight.w600,
                    //       )),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.black54,
                            labelText: 'NAME',
                            labelStyle: TextStyle(color: Colors.red),
                            icon: Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                          ),
                          child: Text(user?['username'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        const SizedBox(height: 25),
                        InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.black54,
                            labelText: 'EMAIL',
                            labelStyle: TextStyle(color: Colors.red),
                            icon: Icon(
                              Icons.mail,
                              color: Colors.grey,
                            ),
                          ),
                          child: Text(user?['email'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        const SizedBox(height: 25),
                        InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.black54,
                            labelText: 'PHONE',
                            labelStyle: TextStyle(color: Colors.red),
                            icon: Icon(
                              Icons.call,
                              color: Colors.grey,
                            ),
                          ),
                          child: Text(user?['number'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        const SizedBox(height: 25),
                        if (user?['type'] == 'driver')
                          InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.black54,
                              labelText: 'VEHICLE NO',
                              labelStyle: TextStyle(color: Colors.red),
                              icon: Icon(
                                Icons.directions_bus,
                                color: Colors.grey,
                              ),
                            ),
                            child: Text(user?['vehicle'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                      ],
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      title: const Text("L O G O U T",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
                      onTap: () {
                        //logout
                        FirebaseAuth.instance.signOut();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Text("No data");
          }
        },
      ),
    );
  }
}
