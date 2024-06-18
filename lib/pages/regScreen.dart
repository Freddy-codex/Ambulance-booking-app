import 'package:ambulance/pages/loginScreen.dart';
import 'package:ambulance/pages/otp_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RegScreen extends StatefulWidget {
  final String type;
  const RegScreen({super.key, required this.type});
  @override
  State<RegScreen> createState() => _RegScreenState();
}

class _RegScreenState extends State<RegScreen> {
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController confirmPWcontroller = TextEditingController();
  final TextEditingController numbercontroller = TextEditingController();
  final TextEditingController vehiclecontroller = TextEditingController();
  bool _isObscure = true;
  bool _isObscure2 = true;
  bool isLoading = false;

  //function for displaying message
  void displayMessageToUser(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning),
        title: Text(message),
      ),
    );
  }

  void register() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    //make sure passwords match
    if (passwordcontroller.text != confirmPWcontroller.text ||
        namecontroller.text.isEmpty ||
        numbercontroller.text.isEmpty) {
      Navigator.pop(context);
      if (passwordcontroller.text != confirmPWcontroller.text) {
        displayMessageToUser("Passwords don't Match!", context);
      } else {
        displayMessageToUser("Missing values", context);
      }
    } else {
      //try creating new user
      try {
        //create new user
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailcontroller.text, password: passwordcontroller.text);
        User? tempUser = FirebaseAuth.instance.currentUser;
        if (tempUser != null) {
          await tempUser.delete();
          sendcode();
        }
      } on FirebaseAuthException catch (e) {
        //pop loading circle
        if (context.mounted) Navigator.pop(context);

        //display error message
        displayMessageToUser(e.code, context);
      }
    }
  }

  sendcode() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '+91${numbercontroller.text}',
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            Get.snackbar('Error occured', e.code);
            setState(() {
              isLoading = false; // Reset loading state on error
            });
          },
          codeSent: (String vid, int? token) {
            if (widget.type == 'driver') {
              Get.to(() => OtpPage(
                    vid: vid,
                    type: widget.type,
                    name: namecontroller.text,
                    email: emailcontroller.text,
                    number: numbercontroller.text,
                    password: passwordcontroller.text,
                    vehicle: vehiclecontroller.text,
                  ));
              setState(() {
                isLoading = false; // Reset loading state on error
              });
            } else {
              Get.to(() => OtpPage(
                    vid: vid,
                    type: widget.type,
                    name: namecontroller.text,
                    email: emailcontroller.text,
                    number: numbercontroller.text,
                    password: passwordcontroller.text,
                  ));
              setState(() {
                isLoading = false; // Reset loading state on error
              });
            }
          },
          codeAutoRetrievalTimeout: (vid) {
            setState(() {
              isLoading = false; // Reset loading state on error
            });
          });
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error occured', e.code);
      setState(() {
        isLoading = false; // Reset loading state on error
      });
    } catch (e) {
      Get.snackbar('Error occured', e.toString());
      setState(() {
        isLoading = false; // Reset loading state on error
      });
    }
  }

  //function to create a user document and add to firestore
  Future<void> createUserDocument(UserCredential? userCredential) async {
    if (userCredential != null && userCredential.user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
        'email': userCredential.user!.email,
        'username': namecontroller.text,
        'type': widget.type,
        'token': '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          //thanks for watching
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 201, 9, 9),
                    Color(0xff1d1d1d),
                  ],
                  begin: Alignment.topLeft,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.only(top: 60.0, left: 22),
                child: Text(
                  'Create Your\nAccount',
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                  color: Colors.white,
                ),
                height: double.infinity,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: namecontroller,
                        decoration: const InputDecoration(
                            // hintText: 'Alfred Antony',
                            suffixIcon: Icon(
                              Icons.person_2,
                              color: Colors.grey,
                            ),
                            label: Text(
                              'Full Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB81736),
                              ),
                            )),
                      ),
                      TextField(
                        controller: emailcontroller,
                        decoration: const InputDecoration(
                            suffixIcon: Icon(
                              Icons.mail,
                              color: Colors.grey,
                            ),
                            label: Text(
                              'Gmail',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB81736),
                              ),
                            )),
                      ),
                      TextField(
                        controller: numbercontroller,
                        decoration: const InputDecoration(
                          suffixIcon: Icon(
                            Icons.phone,
                            color: Colors.grey,
                          ),
                          label: Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xffB81736),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType
                            .number, // Set the keyboard type to number
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter
                              .digitsOnly, // Only allow digits
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      if (widget.type == 'driver')
                        TextField(
                          controller: vehiclecontroller,
                          decoration: const InputDecoration(
                              suffixIcon: Icon(
                                Icons.directions_bus,
                                color: Colors.grey,
                              ),
                              label: Text(
                                'Vehicle No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffB81736),
                                ),
                              )),
                        ),
                      TextField(
                        controller: passwordcontroller,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                            label: const Text(
                              'Password',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB81736),
                              ),
                            )),
                      ),
                      TextField(
                        controller: confirmPWcontroller,
                        obscureText: _isObscure2,
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure2
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure2 = !_isObscure2;
                                });
                              },
                            ),
                            label: const Text(
                              'Confirm Password',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB81736),
                              ),
                            )),
                      ),
                      SizedBox(
                        height: (widget.type == 'driver') ? 30 : 60,
                      ),
                      GestureDetector(
                        onTap: register,
                        child: Container(
                          height: 55,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(colors: [
                              Color.fromARGB(255, 206, 6, 6),
                              Color.fromARGB(255, 114, 3, 3),
                            ]),
                          ),
                          child: const Center(
                            child: Text(
                              'SIGN UP',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: (widget.type == 'driver') ? 20 : 50,
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            loginScreen(type: widget.type)));
                              },
                              child: const Text(
                                "Sign in",
                                style: TextStyle(

                                    ///done login page
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
