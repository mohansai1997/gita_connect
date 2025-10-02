import 'package:flutter/material.dart';

void main() => runApp(HelloApp());

class HelloApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: HelloScreen(),
    );
  }
}

class HelloScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              'SUCCESS!',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Flutter app is working!',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}