// import 'dart:convert';

// import 'package:ambulance/pages/notification_services.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class NotiHome extends StatefulWidget {
//   const NotiHome({super.key});

//   @override
//   State<NotiHome> createState() => _NotiHomeState();
// }

// class _NotiHomeState extends State<NotiHome> {
//   NotificationServices notificationServices = NotificationServices();

//   String tok = "Test";

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     notificationServices.requestNotificationPermission();
//     notificationServices.firebaseInit(context);
//     notificationServices.setupInteractMessage(context);
//     // notificationServices.isTokenRefresh();
//     notificationServices.getDeviceToken().then((value) {
//       print('Device Token:');
//       print(value);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Notifications'),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//         ),
//         body: Center(
//           child: Column(
//             children: [
//               TextButton(
//                 onPressed: () {
//                   notificationServices.getDeviceToken().then((value) async {
//                     var data = {
//                       'to': value.toString(),
//                       'priority': 'high',
//                       'notification': {
//                         'title': 'MEDEX',
//                         'body': value.toString()
//                       }
//                     };
//                     await http.post(
//                         Uri.parse('https://fcm.googleapis.com/fcm/send'),
//                         body: jsonEncode(data),
//                         headers: {
//                           'Content-Type': 'application/json; charset=UTF-8',
//                           'Authorization':
//                               'key=AAAA6Ia6bjo:APA91bEf5tIHVpYuGMSV2GSIFNBWQTBjfdIC4XAa8GETVu9t8gUzhuP2YyXycZEMt4zBsLxft9GrloEZXWhFQTUcUQwBIGFiC1Ku9q5YzqLXwZPZxvpYZN-6m1QMb9cyY9B4pvrCeWYa'
//                         });
//                   });
//                 },
//                 child: const Text(
//                   "Send Notification",
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontSize: 20,
//                   ),
//                 ),
//               ),
//               TextButton(
//                   onPressed: () {
//                     notificationServices.getDeviceToken().then((value) async {
//                       setState(() {
//                         tok = value.toString();
//                         print('TOK: $tok');
//                       });
//                     });
//                   },
//                   child: Text(tok)),
//             ],
//           ),
//         ));
//   }
// }
