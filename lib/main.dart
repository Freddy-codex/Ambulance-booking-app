import 'package:ambulance/auth/auth.dart';
import 'package:ambulance/auth/number_auth.dart';
import 'package:ambulance/firebase_options.dart';
import 'package:ambulance/pages/delivery_state.dart';
import 'package:ambulance/pages/driver_page.dart';
import 'package:ambulance/pages/forgot_password.dart';
import 'package:ambulance/pages/home_page.dart';
import 'package:ambulance/pages/phone_number.dart';
import 'package:ambulance/pages/profile_page.dart';
import 'package:ambulance/pages/tracking.dart';
import 'package:ambulance/pages/users_page.dart';
import 'package:ambulance/pages/notifications.dart';
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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: ('inter'),
        useMaterial3: true,
      ),
      home: const AuthPage(),
      routes: {
        'homepage': (context) => const HomePage(),
        'driverspage': (context) => const DriverPage(),
        'authpage': (context) => const AuthPage(),
        'profilepage': (context) => ProfilePage(),
        'userspage': (context) => const UsersPage(),
        'trackingpage': (context) => const TrackingPage(),
      },
    );
  }
}
