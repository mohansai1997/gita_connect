import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test App'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Hello from Test App!',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 16),
              Text('App is working correctly'),
            ],
          ),
        ),
      ),
    );
  }
}