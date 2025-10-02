import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/screens.dart';

/// App route names
class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String auth = '/auth';
  static const String profile = '/profile';
  static const String shorts = '/shorts';
  static const String courses = '/courses';
  static const String events = '/events';
  static const String gallery = '/gallery';
  static const String donations = '/donations';
}

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final appState = ref.watch(appStateNotifierProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: appState.isLoading ? AppRoutes.splash : AppRoutes.home,
    redirect: (context, state) {
      final isLoading = appState.isLoading;
      final isAuthenticated = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnAuth = state.matchedLocation == AppRoutes.auth;
      
      // Show splash screen while loading
      if (isLoading && !isOnSplash) {
        return AppRoutes.splash;
      }
      
      // Once loaded, redirect from splash to appropriate screen
      if (!isLoading && isOnSplash) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.auth;
      }
      
      // Redirect to auth if not authenticated (except if already on auth)
      // Temporarily disabled for development - allow access without auth
      // if (!isAuthenticated && !isOnAuth && !isOnSplash && !isLoading) {
      //   return AppRoutes.auth;
      // }
      
      // Redirect to home if authenticated and on auth screen
      if (isAuthenticated && isOnAuth) {
        return AppRoutes.home;
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Splash Route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Route
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home Route
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Profile Route
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          
          // Shorts Route
          GoRoute(
            path: AppRoutes.shorts,
            name: 'shorts',
            builder: (context, state) => const ShortsScreen(),
          ),
          
          // Courses Route
          GoRoute(
            path: AppRoutes.courses,
            name: 'courses',
            builder: (context, state) => const CoursesScreen(),
          ),
          
          // Events Route
          GoRoute(
            path: AppRoutes.events,
            name: 'events',
            builder: (context, state) => const EventsScreen(),
          ),
          
          // Gallery Route
          GoRoute(
            path: AppRoutes.gallery,
            name: 'gallery',
            builder: (context, state) => const GalleryScreen(),
          ),
          
          // Donations Route
          GoRoute(
            path: AppRoutes.donations,
            name: 'donations',
            builder: (context, state) => const DonationsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.error}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});