import 'package:flutter/material.dart';
import 'regScreen.dart';

import 'loginScreen.dart';

class WelcomeScreen2 extends StatelessWidget {
  final String type;
  const WelcomeScreen2({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
          Color(0xffB81736),
          Color(0xff281537),
        ])),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.only(top: 200.0),
            child: FittedBox(
              fit: BoxFit.scaleDown, // Adjust the fit mode as needed
              child: SizedBox(
                width: 100.0, // Specify the desired width
                height: 100.0, // Specify the desired height
                child: Image(
                  image: AssetImage('assets/driver.jpeg'),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 100,
          ),
          const Text(
            'Welcome DRIVER',
            style: TextStyle(fontSize: 30, color: Colors.white),
          ),
          const SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => loginScreen(type: type)));
            },
            child: Container(
              height: 53,
              width: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white),
              ),
              child: const Center(
                child: Text(
                  'SIGN IN',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RegScreen(type: type)));
            },
            child: Container(
              height: 53,
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white),
              ),
              child: const Center(
                child: Text(
                  'SIGN UP',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ),
          const Spacer(),
          // const Text(
          //   'Login with Social Media',
          //   style: TextStyle(fontSize: 17, color: Colors.white),
          // ), //
          // const SizedBox(
          //   height: 12,
          // ),
          // const Image(image: AssetImage('assets/social.png'))
        ]),
      ),
    );
  }
}
