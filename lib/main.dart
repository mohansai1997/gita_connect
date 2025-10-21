import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/user_type.dart';
import 'screens/login_page.dart';
import 'screens/profile_completion_page.dart';
import 'screens/profile_screen.dart';
import 'screens/full_gallery_page.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/gallery_management_screen.dart';
import 'screens/admin/video_management_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_user_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/gallery_service.dart';
import 'services/video_service.dart';
import 'widgets/dynamic_video_categories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Configure Firebase Auth to completely disable reCAPTCHA and use app verification
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: false,
    forceRecaptchaFlow: false,
  );
  
  // Initialize notification services
  await NotificationService.initialize();
  await FCMService.initialize();
  
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
          return const LoginPage();
        }
        
        final currentUser = snapshot.data!;
        
        // User is authenticated, show ProfileChecker that will handle the logic
        return ProfileChecker(
          user: currentUser,
          profileService: _profileService,
        );
      },
    );
  }

}

// Widget that directly manages profile checking without any caching
class ProfileChecker extends StatefulWidget {
  final User user;
  final FirestoreUserService profileService;
  
  const ProfileChecker({
    super.key,
    required this.user,
    required this.profileService,
  });
  
  @override
  State<ProfileChecker> createState() => _ProfileCheckerState();
}

class _ProfileCheckerState extends State<ProfileChecker> {
  bool? _isProfileComplete;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }
  
  Future<void> _checkProfileStatus() async {
    try {
      debugPrint('=== Simplified Profile Check Started ===');
      debugPrint('User UID: ${widget.user.uid}');
      debugPrint('Phone: ${widget.user.phoneNumber}');
      
      // Simply check if profile exists in Firestore
      debugPrint('Checking if profile exists in Firestore...');
      final existingProfile = await widget.profileService.getUserProfile(widget.user.uid);
      
      if (existingProfile == null) {
        // No profile exists - show profile completion page
        // We'll create the profile only when user completes it
        debugPrint('No profile found in database');
        debugPrint('=== New User - Show Profile Completion (no DB save yet) ===');
        
        if (mounted) {
          setState(() {
            _isProfileComplete = false;
            _isLoading = false;
          });
        }
        return;
      }
      
      // Profile exists - check if it's complete
      debugPrint('Profile exists in database:');
      debugPrint('- Name: ${existingProfile.name}');
      debugPrint('- Email: ${existingProfile.email}');
      debugPrint('- Is Complete: ${existingProfile.isProfileComplete}');
      
      final isComplete = existingProfile.isProfileComplete;
      debugPrint(isComplete 
        ? '=== Existing User with Complete Profile - Show Home ===' 
        : '=== Existing User with Incomplete Profile - Show Profile Completion ===');
      
      if (mounted) {
        setState(() {
          _isProfileComplete = isComplete;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('Error checking profile: $e');
      debugPrint('=== Error Occurred - Show Profile Completion ===');
      
      if (mounted) {
        setState(() {
          _isProfileComplete = false;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show appropriate screen based on fresh profile status
    if (_isProfileComplete == true) {
      return const GitaConnectHomePage(title: 'Gita Connect');
    } else {
      return const ProfileCompletionPage();
    }
  }
}

class GitaConnectHomePage extends StatefulWidget {
  const GitaConnectHomePage({super.key, required this.title});

  final String title;

  @override
  State<GitaConnectHomePage> createState() => _GitaConnectHomePageState();
}

class _GitaConnectHomePageState extends State<GitaConnectHomePage> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  /// Setup notifications for authenticated user
  Future<void> _setupNotifications() async {
    try {
      // Initialize FCM for reliable server-side notifications
      await FCMService.initialize();
      
      // Subscribe to daily Krishna reminders topic
      await FCMService.subscribeToKrishnaReminders();
      
      debugPrint('✅ FCM notifications set up successfully (server-side scheduling)');
    } catch (e) {
      debugPrint('❌ Error setting up notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Where Every Step Leads You Closer to the Divine',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.grey.shade700,
                height: 0.9,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false, // Remove default hamburger
        actions: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.deepOrange),
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Devotee!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '⭐ VIP Member',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }
                    
                    String userName = 'Devotee';
                    String userTypeDisplay = '⭐ VIP Member';
                    UserType currentUserType = UserType.vip;
                    
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      userName = userData?['name'] ?? 'Devotee';
                      
                      // Get user type from database
                      final userTypeString = userData?['userType'] as String?;
                      currentUserType = UserType.fromString(userTypeString);
                      userTypeDisplay = '${currentUserType.icon} ${currentUserType.displayName}';
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hare Krishna $userName!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userTypeDisplay,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                UserType currentUserType = UserType.vip;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final userTypeString = userData?['userType'] as String?;
                  currentUserType = UserType.fromString(userTypeString);
                }
                
                return ListView(
                  padding: EdgeInsets.zero,
                  children: _buildMenuItems(context, currentUserType),
                );
              },
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

  /// Build menu items based on user type
  List<Widget> _buildMenuItems(BuildContext context, UserType userType) {
    List<Widget> menuItems = [
      // Profile
      ListTile(
        leading: const Icon(Icons.person, color: Colors.deepOrange),
        title: const Text('Profile'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        },
      ),
      
      const Divider(),
      
      // Test Notifications
      ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.deepOrange),
        title: const Text('Test Notification'),
        onTap: () async {
          Navigator.pop(context);
          try {
            await NotificationService.showTestNotification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Test notification sent! Check your notification panel.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
      
      // Test FCM
      ListTile(
        leading: const Icon(Icons.cloud, color: Colors.deepOrange),
        title: const Text('Test FCM'),
        onTap: () async {
          Navigator.pop(context);
          try {
            await FCMService.sendTestNotification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ FCM test sent! This proves server notifications work.'),
                backgroundColor: Colors.blue,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ FCM Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
      
      // Gallery
      ListTile(
        leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
        title: const Text('Gallery'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FullGalleryPage(),
            ),
          );
        },
      ),
    ];

    // Admin Section - Only visible to admin users
    if (userType.isAdmin) {
      menuItems.addAll([
        const Divider(thickness: 2),
        
        // Admin Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Admin Dashboard
        ListTile(
          leading: Icon(Icons.dashboard, color: Colors.red.shade700),
          title: const Text('Admin Dashboard'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
          },
        ),
        
        // Manage Gallery
        ListTile(
          leading: Icon(Icons.photo_library_outlined, color: Colors.red.shade700),
          title: const Text('Manage Gallery'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GalleryManagementScreen(),
              ),
            );
          },
        ),
        
        // Manage Videos
        ListTile(
          leading: Icon(Icons.video_library_outlined, color: Colors.red.shade700),
          title: const Text('Manage Videos'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VideoManagementScreen(),
              ),
            );
          },
        ),
        
        // Manage Notifications
        ListTile(
          leading: Icon(Icons.notifications_outlined, color: Colors.red.shade700),
          title: const Text('Manage Notifications'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification Management coming soon!'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
        
        // Manage Users
        ListTile(
          leading: Icon(Icons.people_outline, color: Colors.red.shade700),
          title: const Text('Manage Users'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User Management coming soon!'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ]);
    }

    // Logout - Always at the bottom
    menuItems.addAll([
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
    ]);

    return menuItems;
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
          const BhaktiBitesWidget(),
          
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
          
          // Gallery Photos Grid
          const GalleryWidget(),
          
          const SizedBox(height: 24),
          
          // Dynamic Video Categories Section (all categories except Bhakti Bites)
          const DynamicVideoCategoriesWidget(),
          
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


}

// Gallery Widget to display photos from Firebase Storage
class GalleryWidget extends StatefulWidget {
  const GalleryWidget({super.key});

  @override
  State<GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<GalleryWidget> {
  final GalleryService _galleryService = GalleryService();
  List<String> _photoUrls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGalleryPhotos();
  }

  Future<void> _loadGalleryPhotos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final photos = await _galleryService.getGalleryPhotos();
      
      if (mounted) {
        setState(() {
          _photoUrls = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load gallery photos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPhotoGrid() {
    if (_photoUrls.isEmpty) {
      return Container(
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
                'No photos found in gallery',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _photoUrls.length > 6 ? 6 : _photoUrls.length, // Show max 6 photos
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullScreenImage(context, _photoUrls[index]),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _photoUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.deepOrange,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade500,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepOrange,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading gallery',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loadGalleryPhotos,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildPhotoGrid(),
        if (_photoUrls.length > 6) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FullGalleryPage(),
                ),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: Text('View All ${_photoUrls.length} Photos'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepOrange,
            ),
          ),
        ],
      ],
    );
  }
}

// Widget for displaying dynamic Bhakti Bites from Firestore
class BhaktiBitesWidget extends StatefulWidget {
  const BhaktiBitesWidget({super.key});

  @override
  State<BhaktiBitesWidget> createState() => _BhaktiBitesWidgetState();
}

class _BhaktiBitesWidgetState extends State<BhaktiBitesWidget> {
  List<Map<String, dynamic>> _bhaktiBites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _debugDatabase();
    _loadBhaktiBites();
  }

  Future<void> _debugDatabase() async {
    await VideoService.debugAllVideos();
  }

  Future<void> _loadBhaktiBites() async {
    try {
      print('DEBUG: Starting to load Bhakti Bites...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await VideoService.getBhaktiBites();
      
      print('DEBUG: Loaded ${videos.length} Bhakti Bites videos');
      
      if (mounted) {
        setState(() {
          _bhaktiBites = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR: Failed to load Bhakti Bites: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load Bhakti Bites: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 140,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
              const SizedBox(height: 8),
              Text('Error loading videos', style: TextStyle(color: Colors.red.shade600)),
              TextButton(onPressed: _loadBhaktiBites, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_bhaktiBites.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 40, color: Colors.grey.shade500),
              const SizedBox(height: 8),
              Text('No Bhakti Bites found', style: TextStyle(color: Colors.grey.shade600)),
              Text('Ask admin to add some videos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _bhaktiBites.length,
        itemBuilder: (context, index) {
          final video = _bhaktiBites[index];
          final title = video['title'] ?? 'Untitled';
          final thumbnailUrl = video['thumbnailUrl'] ?? '';
          final url = video['url'] ?? '';

          return GestureDetector(
            onTap: () => _launchVideo(url),
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
                        image: thumbnailUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(thumbnailUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Fallback handled by container color
                                },
                              )
                            : null,
                      ),
                      child: thumbnailUrl.isEmpty
                          ? Icon(
                              Icons.video_library,
                              color: Colors.deepOrange.shade400,
                              size: 48,
                            )
                          : null,
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
                          title,
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
    );
  }

  Future<void> _launchVideo(String url) async {
    try {
      String finalUrl = VideoService.convertToStandardUrl(url);
      final Uri videoUri = Uri.parse(finalUrl);
      
      await launchUrl(
        videoUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open video. Please check if YouTube is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Widget for displaying dynamic Lecture Videos from Firestore
class LectureVideosWidget extends StatefulWidget {
  const LectureVideosWidget({super.key});

  @override
  State<LectureVideosWidget> createState() => _LectureVideosWidgetState();
}

class _LectureVideosWidgetState extends State<LectureVideosWidget> {
  List<Map<String, dynamic>> _lectureVideos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _debugDatabase();
    _loadLectureVideos();
  }

  Future<void> _debugDatabase() async {
    await VideoService.debugAllVideos();
  }

  Future<void> _loadLectureVideos() async {
    try {
      print('DEBUG: Starting to load Lecture Videos...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await VideoService.getLectureVideos();
      
      print('DEBUG: Loaded ${videos.length} Lecture Videos');
      
      if (mounted) {
        setState(() {
          _lectureVideos = videos.take(3).toList(); // Show only first 3
          _isLoading = false;
        });
        print('DEBUG: Set ${_lectureVideos.length} lecture videos in state');
      }
    } catch (e) {
      print('ERROR: Failed to load Lecture Videos: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load lecture videos: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error loading videos', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                  Text('Please check your connection', style: TextStyle(color: Colors.red.shade500, fontSize: 12)),
                ],
              ),
            ),
            TextButton(onPressed: _loadLectureVideos, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_lectureVideos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.video_library_outlined, size: 40, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No lecture videos found', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  Text('Ask admin to add some lecture videos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._lectureVideos.map((video) {
          final title = video['title'] ?? 'Untitled Video';
          final description = video['description'] ?? '';
          final duration = video['duration'] ?? '';
          final thumbnailUrl = video['thumbnailUrl'] ?? '';
          final url = video['url'] ?? '';

          return GestureDetector(
            onTap: () => _launchVideo(url),
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
                      image: thumbnailUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(thumbnailUrl),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Fallback handled by container color
                              },
                            )
                          : null,
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
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (duration.isNotEmpty) ...[
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
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
        }).toList(),
      ],
    );
  }

  Future<void> _launchVideo(String url) async {
    try {
      String finalUrl = VideoService.convertToStandardUrl(url);
      final Uri videoUri = Uri.parse(finalUrl);
      
      await launchUrl(
        videoUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open video. Please check if YouTube is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
