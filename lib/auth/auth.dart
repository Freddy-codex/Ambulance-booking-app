import 'package:ambulance/pages/driver_page.dart';
import 'package:ambulance/pages/home_page.dart';
import 'package:ambulance/pages/user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  // Function to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(
      User? currentUser) async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            User? currentUser = FirebaseAuth.instance.currentUser;
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getUserDetails(currentUser),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // Error
                else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                // Data received
                else if (snapshot.hasData) {
                  // Extract data
                  Map<String, dynamic>? user = snapshot.data!.data();
                  if (user?['type'] == 'user') {
                    return HomePage();
                  } else {
                    return const DriverPage();
                  }
                } else {
                  return const Text("No data");
                }
              },
            );
          }
          // User is not logged in
          else {
            return const user();
          }
        },
      ),
    );
  }
}
