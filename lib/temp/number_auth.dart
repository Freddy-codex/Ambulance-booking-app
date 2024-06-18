// import 'package:ambulance/pages/home_page.dart';
// import 'package:ambulance/pages/phone_number.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class NumberAuth extends StatefulWidget {
//   const NumberAuth({super.key});

//   @override
//   State<NumberAuth> createState() => _NumberAuthState();
// }

// class _NumberAuthState extends State<NumberAuth> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(
//           stream: FirebaseAuth.instance.authStateChanges(),
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               return HomePage();
//             } else {
//               return PhoneNumber();
//             }
//           }),
//     );
//   }
// }
