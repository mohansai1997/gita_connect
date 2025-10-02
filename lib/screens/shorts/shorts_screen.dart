import 'package:flutter/material.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiritual Shorts'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Shorts Coming Soon!', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}