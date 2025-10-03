import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/youtube_short.dart';
import 'widgets/quote/quote_section.dart';

void main() {
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
      home: const GitaConnectHomePage(title: 'Gita Connect - ISKCON Youth'),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Read Today',
                  Icons.book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Listen Audio',
                  Icons.headphones,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Meditate',
                  Icons.self_improvement,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Community',
                  Icons.group,
                  Colors.orange,
                ),
              ),
            ],
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

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

