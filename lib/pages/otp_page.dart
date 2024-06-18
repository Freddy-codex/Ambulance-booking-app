import 'package:ambulance/pages/loginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.vid,
    required this.type,
    required this.name,
    required this.email,
    required this.number,
    required this.password,
    this.vehicle,
  });
  final String vid;
  final String type;
  final String name;
  final String email;
  final String number;
  final String password;
  final String? vehicle;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  var code = "";
  // bool isLoading = false

  signIn() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.vid,
      smsCode: code,
    );

    try {
      //Verify OTP
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Remove the temporary user created during OTP verification
      User? tempUser = FirebaseAuth.instance.currentUser;
      if (tempUser != null) {
        await tempUser.delete();
      }
      // try creating new user
      try {
        //create new user
        UserCredential? userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: widget.email, password: widget.password);

        //create a user document and add to firestore
        createUserDocument(userCredential);

        //pop loading circle
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => loginScreen(type: widget.type)));
      } on FirebaseAuthException catch (e) {
        //pop loading circle
        if (context.mounted) Navigator.pop(context);

        //display error message
        displayMessageToUser(e.code, context);
      }
    } on FirebaseAuthException catch (e) {
      //pop loading circle
      if (context.mounted) Navigator.pop(context);
      Get.snackbar('Error Occured', e.code);
    } catch (e) {
      //pop loading circle
      if (context.mounted) Navigator.pop(context);
      Get.snackbar('Error Occured', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1d1d1d),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(
              height: 50,
            ),
            Image.asset('assets/otp_image.png'),
            const SizedBox(
              height: 20,
            ),
            const Center(
              child: Text(
                'OTP verification',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.white),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Enter OTP sent to +91 ${widget.number}',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            textcode(),
            const SizedBox(
              height: 50,
            ),
            button(),
          ],
        ),
      ),
    );
  }

  Widget textcode() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: const Color.fromARGB(226, 234, 239, 243),
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
        color: Colors.white,
        border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          const BoxShadow(
            color: Color.fromARGB(255, 158, 158, 158),
            blurRadius: 5.0,
          )
        ]);

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Pinput(
          length: 6,
          onChanged: (value) {
            setState(() {
              code = value;
            });
          },
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
        ),
      ),
    );
  }

  Widget button() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          signIn();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16.0),
          backgroundColor: Color.fromARGB(255, 3, 125, 224),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 80),
          child: Text(
            'Verify & Proceed',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  //function for displaying message
  void displayMessageToUser(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }

  //function to create a user document and add to firestore
  Future<void> createUserDocument(UserCredential? userCredential) async {
    if (userCredential != null && userCredential.user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
        'email': userCredential.user!.email,
        'username': widget.name,
        'type': widget.type,
        'number': widget.number,
        'token': '',
        if (widget.type == 'driver') 'vehicle': widget.vehicle,
      });
    }
  }
}