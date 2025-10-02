import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Hello Gita Connect')),
        body: Center(
          child: Text(
            'Hello World!\nApp is working!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}