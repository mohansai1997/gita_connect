import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simplified main without Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Set system UI overlay styles
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    debugPrint('Basic initialization completed');
    
  } catch (e, stackTrace) {
    debugPrint('Basic initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  runApp(
    const ProviderScope(
      child: SimpleGitaConnectApp(),
    ),
  );
}

class SimpleGitaConnectApp extends StatelessWidget {
  const SimpleGitaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gita Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SimpleHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gita Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(
                    Icons.temple_hindu,
                    size: 64,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gita Connect',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'ISKCON Youth Spiritual Learning',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'App Successfully Loaded!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Basic Flutter app with Riverpod is working correctly',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            
            // Feature previews
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Features (Coming Next):',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard('📺', 'YouTube Shorts', 'Spiritual short videos'),
                  _buildFeatureCard('📖', 'Daily Quotes', 'Bhagavad Gita wisdom'),
                  _buildFeatureCard('🖼️', 'Temple Gallery', 'Sacred images'),
                  _buildFeatureCard('🎓', 'Lecture Videos', 'In-depth teachings'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}