import 'package:ambulance/pages/loginScreen.dart';
import 'package:flutter/material.dart';
// import 'WelcomeScreen.dart';
// import 'WelcomeScreen2.dart';

class user extends StatelessWidget {
  const user({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedEx', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(218, 0, 0, 0),
      ),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
            Color(0xff1d1d1d),
            Color(0xff1d1d1d),
          ])),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.only(top: 100.0),
              child: FittedBox(
                fit: BoxFit.scaleDown, // Adjust the fit mode as needed
                child: SizedBox(
                  width: 100.0, // Specify the desired width
                  height: 100.0, // Specify the desired height
                  child: Image(
                    image: AssetImage('assets/logo.png'),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 80,
            ),
            const Text(
              'Welcome to MedEx',
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
                        builder: (context) => const loginScreen(type: 'user')));
              },
              child: Container(
                height: 48,
                width: 250,
                decoration: BoxDecoration(
                  // boxShadow: [BoxShadow(color: Colors.black)],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Color(0xfff24407)),
                ),
                child: const Center(
                  child: Text(
                    'USER',
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
                        builder: (context) =>
                            const loginScreen(type: 'driver')));
              },
              child: Container(
                height: 48,
                width: 250,
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      // blurRadius: 10.0,
                      // spreadRadius: 0.0,
                      // offset: Offset(0.0, 3.0)
                    )
                  ],
                  color: Color.fromARGB(255, 221, 63, 6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Color.fromARGB(255, 221, 63, 6)),
                ),
                child: const Center(
                  child: Text(
                    'DRIVER',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Select User Type',
              style: TextStyle(fontSize: 17, color: Colors.white),
            ),
            const SizedBox(
              height: 12,
            ),
            // const SizedBox(
            //     height: 30,
            //     width: 100,
            //     child: Image(image: AssetImage('assets/social.png')))
          ]),
        ),
      ),
    );
  }
}
