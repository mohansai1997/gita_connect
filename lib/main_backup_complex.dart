import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'providers/providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool initializationSuccessful = false;
  
  try {
    // Initialize Firebase with timeout and emulator check
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Firebase initialization timed out - continuing without Firebase');
        throw Exception('Firebase timeout');
      },
    );
    debugPrint('Firebase initialized successfully');
    
    // Initialize Hive for local storage
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('Hive initialized successfully');
    
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
    
    initializationSuccessful = true;
    debugPrint('App initialization completed successfully');
    
  } catch (e, stackTrace) {
    debugPrint('App initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue with app launch even if initialization fails
  }
  
  runApp(
    ProviderScope(
      child: GitaConnectApp(
        initializationSuccessful: initializationSuccessful,
      ),
    ),
  );
}

class GitaConnectApp extends ConsumerWidget {
  const GitaConnectApp({
    super.key,
    required this.initializationSuccessful,
  });

  final bool initializationSuccessful;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If initialization failed, show a simple error app
    if (!initializationSuccessful) {
      return MaterialApp(
        title: 'Gita Connect',
        home: Scaffold(
          appBar: AppBar(title: const Text('Gita Connect')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check the logs and try again.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    // Normal app flow with providers
    final themeMode = ref.watch(themeNotifierProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Gita Connect',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}


