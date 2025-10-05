import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/youtube_short.dart';
import 'screens/login_page.dart';
import 'screens/profile_completion_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GitaConnectApp());
}

class GitaConnectApp extends StatelessWidget {
  const GitaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gita Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const GitaConnectHomePage(title: 'Gita Connect'),
        '/login': (context) => const LoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Wrapper to handle authentication state and profile completion
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirestoreUserService _profileService = FirestoreUserService();
  final AuthService _authService = AuthService();
  String? _lastCheckedUid;
  final Map<String, Future<bool>> _profileCheckCache = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is not authenticated, show login
        if (!snapshot.hasData || snapshot.data == null) {
          // Clear cached profile data when user logs out
          _lastCheckedUid = null;
          _profileCheckCache.clear();
          return const LoginPage();
        }
        
        final currentUser = snapshot.data!;
        
        // Force fresh profile check if this is a different user or first check
        final shouldRefreshProfile = _lastCheckedUid != currentUser.uid;
        
        // User is authenticated, check profile completion
        return FutureBuilder<bool>(
          key: ValueKey('profile_check_${currentUser.uid}_${shouldRefreshProfile ? DateTime.now().millisecondsSinceEpoch : 'cached'}'),
          future: _getCachedProfileCheck(currentUser, forceRefresh: shouldRefreshProfile),
          builder: (context, profileSnapshot) {
            // Show loading while checking profile
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Update cached values
            _lastCheckedUid = currentUser.uid;
            
            // If profile is complete, show home page
            if (profileSnapshot.hasData && profileSnapshot.data == true) {
              return const GitaConnectHomePage(title: 'Gita Connect');
            } else {
              // Profile is not complete, show profile completion page
              return const ProfileCompletionPage();
            }
          },
        );
  }

  Future<bool> _getCachedProfileCheck(User user, {bool forceRefresh = false}) async {
    final cacheKey = user.uid;
    
    // If force refresh or no cache, create new future
    if (forceRefresh || !_profileCheckCache.containsKey(cacheKey)) {
      debugPrint('Creating new profile check for UID: ${user.uid}');
      _profileCheckCache[cacheKey] = _checkAndCreateProfile(user, forceRefresh: forceRefresh);
    } else {
      debugPrint('Using cached profile check for UID: ${user.uid}');
    }
    
    return await _profileCheckCache[cacheKey]!;
  }

  Future<bool> _checkAndCreateProfile(User user, {bool forceRefresh = false}) async {
    try {
      debugPrint('=== Profile Check Started ===');
      debugPrint('User UID: ${user.uid}');
      debugPrint('Phone: ${user.phoneNumber}');
      debugPrint('Force refresh: $forceRefresh');
      
      // Check if profile exists and is complete
      final existingProfile = await _profileService.getUserProfile(user.uid);
      
      if (existingProfile == null) {
        debugPrint('No existing profile found - creating initial profile');
        // Create initial profile for new user
        final success = await _profileService.createInitialProfile(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
        );
        
        debugPrint('Initial profile creation success: $success');
        debugPrint('=== New User - Redirecting to Profile Completion ===');
        return false; // Profile needs to be completed
      }
      
      debugPrint('Existing profile found:');
      debugPrint('- Name: ${existingProfile.name}');
      debugPrint('- Email: ${existingProfile.email}');
      debugPrint('- Is Complete: ${existingProfile.isProfileComplete}');
      
      // Check if existing user's profile is complete
      if (existingProfile.isProfileComplete) {
        debugPrint('=== Existing User with Complete Profile - Redirecting to Home ===');
        return true;
      } else {
        debugPrint('=== Existing User with Incomplete Profile - Redirecting to Profile Completion ===');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking profile: $e');
      debugPrint('=== Error Occurred - Redirecting to Profile Completion ===');
      return false; // Assume profile needs completion if error occurs
    }
  }
}

// Remove duplicate class extension and close AuthWrapper properly

class GitaConnectHomePage extends StatelessWidget {
  const GitaConnectHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        automaticallyImplyLeading: false, // Remove default hamburger
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context),
      body: const HomeContent(),
    );
  }

  Widget _buildProfileDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.deepOrange),
                ),
                SizedBox(height: 16),
                Text(
                  'Welcome, Devotee!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your spiritual journey continues...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepOrange),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile page coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.deepOrange),
                  title: const Text('My Courses'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Courses page coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.deepOrange),
                  title: const Text('Bookmarks'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bookmarks feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.deepOrange),
                  title: const Text('Reading History'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History feature coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.deepOrange),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings page coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.deepOrange),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help page coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldLogout == true) {
                      try {
                        await AuthService().signOut();
                        // Clear test mode authentication
                        AuthService().clearTestMode();
                        if (context.mounted) {
                          // Navigate to login page
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error logging out: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gita Connect v1.0.0\nISKCON Youth App',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"If one reads Bhagavad-gītā regularly and attentively, he can surpass all studies of Vedic literature"',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— A. C. Bhaktivedanta Swami Prabhupada',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bhakti Bites
          Text(
            'Bhakti Bites',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ShortsData.getFeaturedShorts().length,
              itemBuilder: (context, index) {
                final short = ShortsData.getFeaturedShorts()[index];
                return GestureDetector(
                  onTap: () => _launchVideo(short.url),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Thumbnail
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              image: DecorationImage(
                                image: NetworkImage(short.thumbnailUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Fallback if thumbnail fails to load
                                },
                              ),
                            ),
                          ),
                          // Play button overlay
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                          // Title overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Text(
                                short.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gallery Section
          Text(
            'Gallery',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          
          // Placeholder for gallery content - to be added later
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gallery content coming soon...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lecture Videos Section
          Text(
            'Lecture Videos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            final lectureUrls = [
              'https://www.youtube.com/watch?v=T9ImysdFAZw',
              'https://www.youtube.com/watch?v=FIQqKyFJ_xw',
              'https://www.youtube.com/watch?v=jn9TrsgdKU4',
            ];
            final lectureTitles = [
              'Bhagavad Gita Chapter 1 - Arjuna Vishada Yoga',
              'Krishna Consciousness in Daily Life',
              'Understanding the Soul - Bhagavad Gita Wisdom',
            ];
            final lectureDurations = ['45:30', '32:15', '28:45'];
            
            return GestureDetector(
              onTap: () => _launchVideo(lectureUrls[index]),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lectureTitles[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lectureDurations[index],
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.play_circle_outline,
                                color: Colors.deepOrange.shade600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Success indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gita Connect Successfully Running! 🎉',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Your ISKCON spiritual learning app is ready!',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to launch videos
  Future<void> _launchVideo(String url) async {
    try {
      // For shorts URLs, always convert to regular YouTube URL first for consistent behavior
      String finalUrl = _convertToRegularYouTubeUrl(url);
      final Uri videoUri = Uri.parse(finalUrl);
      
      debugPrint('Launching video: $finalUrl');
      
      // Try to launch with external application (YouTube app) first
      // This avoids the in-app browser navigation issues
      bool launched = false;
      
      try {
        await launchUrl(
          videoUri,
          mode: LaunchMode.externalApplication,
        );
        launched = true;
        debugPrint('Successfully launched with external application');
      } catch (e) {
        debugPrint('External app launch failed: $e');
      }
      
      if (!launched) {
        // Fallback: try with platform default
        try {
          await launchUrl(
            videoUri,
            mode: LaunchMode.platformDefault,
          );
          launched = true;
          debugPrint('Successfully launched with platform default');
        } catch (e) {
          debugPrint('Platform default launch failed: $e');
        }
      }
      
      if (!launched) {
        // Final fallback: try original URL if we converted it
        if (finalUrl != url) {
          try {
            final Uri originalUri = Uri.parse(url);
            await launchUrl(
              originalUri,
              mode: LaunchMode.externalApplication,
            );
            launched = true;
            debugPrint('Successfully launched with original URL');
          } catch (e) {
            debugPrint('Original URL launch failed: $e');
          }
        }
      }
      
      if (!launched) {
        throw Exception('All launch methods failed');
      }
      
    } catch (e) {
      debugPrint('Could not launch video: $url');
      debugPrint('Error: $e');
      
      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open video. Please check if YouTube is installed.'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // Convert shorts URL to regular YouTube URL for better compatibility
  String _convertToRegularYouTubeUrl(String url) {
    debugPrint('Converting URL: $url');
    
    if (url.contains('/shorts/')) {
      // Extract video ID from shorts URL
      final RegExp regExp = RegExp(r'/shorts/([a-zA-Z0-9_-]{11})');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final videoId = match.group(1);
        final convertedUrl = 'https://www.youtube.com/watch?v=$videoId';
        debugPrint('Converted shorts URL to: $convertedUrl');
        return convertedUrl;
      }
    } else if (url.contains('youtu.be/')) {
      // Handle youtu.be short URLs
      final RegExp regExp = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final videoId = match.group(1);
        final convertedUrl = 'https://www.youtube.com/watch?v=$videoId';
        debugPrint('Converted youtu.be URL to: $convertedUrl');
        return convertedUrl;
      }
    }
    
    debugPrint('No conversion needed, returning original URL');
    return url; // Return original URL if not a shorts or youtu.be URL
  }


}

