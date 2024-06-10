import 'package:flutter/material.dart';

class ShowAmbulances extends StatelessWidget {
  const ShowAmbulances({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Ambulances'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
          },
          backgroundColor: Colors.blue,
          child: const Icon(
            size: 40.0,
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
