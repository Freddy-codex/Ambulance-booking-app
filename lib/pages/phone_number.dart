// import 'package:ambulance/pages/otp_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class PhoneNumber extends StatefulWidget {
//   PhoneNumber({
//     super.key,
//     required this.type,
//     required this.name,
//     required this.email,
//     required this.number,
//     required this.password,
//   });
//   final String type;
//   final String name;
//   final String email;
//   final String number;
//   final String password;

//   @override
//   State<PhoneNumber> createState() => _PhoneNumberState();
// }

// class _PhoneNumberState extends State<PhoneNumber> {
//   final TextEditingController phonenumber = TextEditingController();
//   bool isLoading = false;

//   @override
//   void dispose() {
//     phonenumber.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         title: const Text('Mobile Verification'),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(30.0),
//           child: Column(
//             children: [
//               const SizedBox(
//                 height: 180,
//               ),
//               const Text(
//                 'Enter your Phone Number',
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//               TextField(
//                 controller: phonenumber,
//                 decoration: InputDecoration(
//                   labelText: 'Phone Number',
//                   // hintText: '+91 0000000000',
//                   hintStyle: const TextStyle(color: Colors.grey),
//                   fillColor: Colors.grey[200],
//                   filled: true,
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: const BorderSide(color: Colors.black),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: const BorderSide(color: Colors.red),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//               MaterialButton(
//                 onPressed: sendcode,
//                 color: const Color.fromARGB(255, 235, 16, 0),
//                 child: const Text(
//                   'Send OTP',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   sendcode() async {
//     setState(() {
//       isLoading = true; // Set loading state to true
//     });
//     // Show loading indicator if loading
//     if (isLoading) {
//       //show loading circle
//       showDialog(
//         barrierDismissible: false,
//         context: context,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//           phoneNumber: '+91${phonenumber.text}',
//           verificationCompleted: (PhoneAuthCredential credential) {},
//           verificationFailed: (FirebaseAuthException e) {
//             Get.snackbar('Error occured', e.code);
//             setState(() {
//               isLoading = false; // Reset loading state on error
//             });
//           },
//           codeSent: (String vid, int? token) {
//             Get.to(() => OtpPage(
//                   vid: vid,
//                   type: widget.type,
//                   name: widget.name,
//                   email: widget.email,
//                   number: widget.number,
//                   password: widget.password,
//                 ));
//             setState(() {
//               isLoading = false; // Reset loading state on error
//             });
//           },
//           codeAutoRetrievalTimeout: (vid) {
//             setState(() {
//               isLoading = false; // Reset loading state on error
//             });
//           });
//     } on FirebaseAuthException catch (e) {
//       Get.snackbar('Error occured', e.code);
//       setState(() {
//         isLoading = false; // Reset loading state on error
//       });
//     } catch (e) {
//       Get.snackbar('Error occured', e.toString());
//       setState(() {
//         isLoading = false; // Reset loading state on error
//       });
//     }
//   }
// }
