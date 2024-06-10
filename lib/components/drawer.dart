import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  //logout function
  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //DrawerHeader
              const DrawerHeader(
                child: Icon(CupertinoIcons.plus_circle),
              ),

              //Home Tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 15),
                child: ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text("H O M E"),
                  onTap: () {
                    //pop drawer
                    Navigator.pop(context);
                  },
                ),
              ),

              //Profile Tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("P R O F I L E"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, 'profilepage');
                  },
                ),
              ),

              //Users Tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text("U S E R S"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, 'userspage');
                  },
                ),
              ),
            ],
          ),

          //LOGOUT
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("L O G O U T"),
              onTap: () {
                Navigator.pop(context);
                //logout
                logout();
              },
            ),
          )
        ],
      ),
    );
  }
}
