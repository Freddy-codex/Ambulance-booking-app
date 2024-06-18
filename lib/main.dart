import 'package:ambulance/auth/auth.dart';
import 'package:ambulance/services/firebase_options.dart';
import 'package:ambulance/services/delivery_state.dart';
import 'package:ambulance/pages/driver_home.dart';
import 'package:ambulance/pages/user_home.dart';
import 'package:ambulance/pages/profile_page.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    ChangeNotifierProvider(
      create: (context) => DeliveryState(),
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xff1d1d1d)));
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        // fontFamily: ('inter'),
        useMaterial3: true,
      ),
      home: const AuthPage(),
      routes: {
        'authpage': (context) => const AuthPage(),
        'profilepage': (context) => ProfilePage(),
        'userhome': (context) => UserHome(),
        'driverhome': (context) => const DriverHome(),
      },
    );
  }
}
