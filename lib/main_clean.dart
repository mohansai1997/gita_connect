import 'package:flutter/material.dart';

void main() {
  runApp(CleanApp());
}

class CleanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CleanHome(),
    );
  }
}

class CleanHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working App'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'APP WORKING!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Flutter is running successfully',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}