import 'package:flutter/material.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Donations Coming Soon!', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}