import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../providers/providers.dart';
import '../../router/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'D',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    Text(
                      currentUser?.displayName ?? 'Devotee',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Phone/Email
                    Text(
                      currentUser?.phoneNumber ?? currentUser?.email ?? '+91 98765 43210',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Join Date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member since 2024',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    '12',
                    'Courses\nCompleted',
                    Icons.school,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    '45',
                    'Hours\nWatched',
                    Icons.play_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    '28',
                    'Days\nStreak',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Menu Items
            _buildMenuItem(
              context,
              'My Courses',
              MdiIcons.bookOpenPageVariant,
              () => context.go(AppRoutes.courses),
            ),
            _buildMenuItem(
              context,
              'Saved Videos',
              Icons.bookmark,
              () {
                // TODO: Navigate to saved videos
              },
            ),
            _buildMenuItem(
              context,
              'Download Manager',
              Icons.download,
              () {
                // TODO: Navigate to downloads
              },
            ),
            _buildMenuItem(
              context,
              'Notifications',
              Icons.notifications,
              () {
                // TODO: Navigate to notification settings
              },
            ),
            _buildMenuItem(
              context,
              'Theme',
              themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
              () {
                ref.read(themeNotifierProvider.notifier).toggleTheme();
              },
              trailing: Text(
                themeMode == ThemeMode.light ? 'Light' : 'Dark',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            _buildMenuItem(
              context,
              'Settings',
              Icons.settings,
              () {
                // TODO: Navigate to settings
              },
            ),
            _buildMenuItem(
              context,
              'Help & Support',
              Icons.help,
              () {
                // TODO: Navigate to help
              },
            ),
            _buildMenuItem(
              context,
              'About',
              Icons.info,
              () {
                _showAboutDialog(context);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSignOutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Gita Connect',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 ISKCON. All rights reserved.',
      children: [
        const Text(
          '\nGita Connect is your spiritual learning companion, '
          'bringing you closer to Krishna consciousness through '
          'courses, videos, and community engagement.',
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement sign out logic
              context.go(AppRoutes.auth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}