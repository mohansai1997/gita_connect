import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../models/user_type.dart';
import '../../services/firestore_user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  UserType? _selectedUserType;
  String _selectedTimeFilter = 'All Time';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'All Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          UserOverviewTab(),
          AllUsersTab(
            searchQuery: _searchQuery,
            selectedUserType: _selectedUserType,
            selectedTimeFilter: _selectedTimeFilter,
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onUserTypeChanged: (type) => setState(() => _selectedUserType = type),
            onTimeFilterChanged: (filter) => setState(() => _selectedTimeFilter = filter),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showPromoteUserDialog,
              backgroundColor: Colors.deepOrange.shade700,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Add Admin', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  void _showPromoteUserDialog() {
    showDialog(
      context: context,
      builder: (context) => PromoteUserDialog(),
    );
  }
}

/// Overview Tab - User Statistics and Analytics
class UserOverviewTab extends StatelessWidget {
  const UserOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final stats = _calculateUserStats(users);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Users',
                      stats['totalUsers'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'New This Week',
                      stats['newThisWeek'].toString(),
                      Icons.person_add,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Admin Users',
                      stats['adminUsers'].toString(),
                      Icons.admin_panel_settings,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'VIP Users',
                      stats['vipUsers'].toString(),
                      Icons.star,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // User Type Distribution
              Text(
                'User Type Distribution',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildUserTypeDistribution(stats),
              
              const SizedBox(height: 32),
              
              // Recent Users
              Text(
                'Recent Users',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentUsersList(users),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _calculateUserStats(List<QueryDocumentSnapshot> users) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    int totalUsers = users.length;
    int newThisWeek = 0;
    int adminUsers = 0;
    int vipUsers = 0;
    int premiumUsers = 0;
    int basicUsers = 0;

    for (final doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final userType = data['userType'] as String?;
      final createdAt = data['createdAt'] as Timestamp?;

      // Count new users this week
      if (createdAt != null && createdAt.toDate().isAfter(weekAgo)) {
        newThisWeek++;
      }

      // Count by user type
      switch (userType) {
        case 'admin':
          adminUsers++;
          break;
        case 'vip':
          vipUsers++;
          break;
        case 'premium':
          premiumUsers++;
          break;
        case 'basic':
        default:
          basicUsers++;
          break;
      }
    }

    return {
      'totalUsers': totalUsers,
      'newThisWeek': newThisWeek,
      'adminUsers': adminUsers,
      'vipUsers': vipUsers,
      'premiumUsers': premiumUsers,
      'basicUsers': basicUsers,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeDistribution(Map<String, int> stats) {
    final types = [
      {'name': 'Admin', 'count': stats['adminUsers']!, 'color': Colors.orange},
      {'name': 'VIP', 'count': stats['vipUsers']!, 'color': Colors.purple},
      {'name': 'Premium', 'count': stats['premiumUsers']!, 'color': Colors.blue},
      {'name': 'Basic', 'count': stats['basicUsers']!, 'color': Colors.grey},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: types.map((type) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: type['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  (type['count'] as int).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentUsersList(List<QueryDocumentSnapshot> users) {
    // Sort by creation date and take first 5
          final recentUsers = users
              .where((doc) => (doc.data() as Map<String, dynamic>)['createdAt'] != null)
              .toList()
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
              return bTime.compareTo(aTime);
            });

          final displayUsers = recentUsers.take(5).toList();

          return Card(
            child: Column(
              children: displayUsers.map((doc) {
                final profile = UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepOrange.shade100,
              child: Text(
                (profile.name?.isNotEmpty == true ? profile.name![0] : '?').toUpperCase(),
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(profile.name ?? 'No Name'),
            subtitle: Text(profile.phoneNumber),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: profile.userType.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile.userType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: profile.userType.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// All Users Tab - Complete user list with search and filters
class AllUsersTab extends StatelessWidget {
  final String searchQuery;
  final UserType? selectedUserType;
  final String selectedTimeFilter;
  final Function(String) onSearchChanged;
  final Function(UserType?) onUserTypeChanged;
  final Function(String) onTimeFilterChanged;

  const AllUsersTab({
    super.key,
    required this.searchQuery,
    required this.selectedUserType,
    required this.selectedTimeFilter,
    required this.onSearchChanged,
    required this.onUserTypeChanged,
    required this.onTimeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search users by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              
              // Filter Row
              Row(
                children: [
                  // User Type Filter
                  Expanded(
                    child: DropdownButtonFormField<UserType?>(
                      value: selectedUserType,
                      decoration: const InputDecoration(
                        labelText: 'User Type',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<UserType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...UserType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        )),
                      ],
                      onChanged: onUserTypeChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Time Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTimeFilter,
                      decoration: const InputDecoration(
                        labelText: 'Join Date',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                        DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                        DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                        DropdownMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),
                      ],
                      onChanged: (value) => onTimeFilterChanged(value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allUsers = snapshot.data!.docs;
              final filteredUsers = _applyAllFilters(allUsers);

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final doc = filteredUsers[index];
                  final profile = UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
                  return UserListTile(profile: profile);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _applyAllFilters(List<QueryDocumentSnapshot> users) {
    List<QueryDocumentSnapshot> filteredUsers = List.from(users);

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredUsers = filteredUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name']?.toString().toLowerCase() ?? '';
        final phone = data['phoneNumber']?.toString().toLowerCase() ?? '';
        final email = data['email']?.toString().toLowerCase() ?? '';

        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    }

    // Filter by user type
    if (selectedUserType != null) {
      filteredUsers = filteredUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userType = data['userType']?.toString();
        return userType == selectedUserType!.name;
      }).toList();
    }

    // Filter by time range
    if (selectedTimeFilter != 'All Time') {
      DateTime filterDate;
      switch (selectedTimeFilter) {
        case 'This Week':
          filterDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'This Month':
          filterDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          filterDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        default:
          filterDate = DateTime.now().subtract(const Duration(days: 365 * 10));
      }

      filteredUsers = filteredUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        return createdAt.toDate().isAfter(filterDate);
      }).toList();
    }

    // Sort by creation date (newest first)
    filteredUsers.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['createdAt'] as Timestamp?;
      final bTime = bData['createdAt'] as Timestamp?;
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });

    return filteredUsers;
  }
}



/// User List Tile - Reusable user item widget
class UserListTile extends StatelessWidget {
  final UserProfile profile;

  const UserListTile({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: profile.userType.color.withOpacity(0.1),
          child: Text(
            (profile.name?.isNotEmpty == true ? profile.name![0] : '?').toUpperCase(),
            style: TextStyle(
              color: profile.userType.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          profile.name ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.phoneNumber),
            if (profile.email?.isNotEmpty == true) Text(profile.email!),
            const SizedBox(height: 4),
            Text(
              'Joined ${_formatDate(profile.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: profile.userType.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile.userType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: profile.userType.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(context, value, profile),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_type',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Change Type'),
                    ],
                  ),
                ),
                if (profile.userType != UserType.admin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Make Admin', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                if (profile.userType == UserType.admin)
                  const PopupMenuItem(
                    value: 'remove_admin',
                    child: Row(
                      children: [
                        Icon(Icons.remove_moderator, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Admin', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showUserProfile(context, profile),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else if (difference < 30) {
      return '${(difference / 7).floor()}w ago';
    } else if (difference < 365) {
      return '${(difference / 30).floor()}mo ago';
    } else {
      return '${(difference / 365).floor()}y ago';
    }
  }

  void _handleUserAction(BuildContext context, String action, UserProfile profile) {
    switch (action) {
      case 'view':
        _showUserProfile(context, profile);
        break;
      case 'edit_type':
        _showEditUserTypeDialog(context, profile);
        break;
      case 'make_admin':
        _promoteToAdmin(context, profile);
        break;
      case 'remove_admin':
        _removeAdminRole(context, profile);
        break;
    }
  }

  void _showUserProfile(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(profile: profile),
    );
  }

  void _showEditUserTypeDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => EditUserTypeDialog(profile: profile),
    );
  }

  void _promoteToAdmin(BuildContext context, UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text('Are you sure you want to make ${profile.name ?? profile.phoneNumber} an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Promote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FirestoreUserService().updateUserType(profile.uid, UserType.admin);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? '${profile.name ?? profile.phoneNumber} promoted to Admin!'
                : 'Failed to promote user. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _removeAdminRole(BuildContext context, UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Role'),
        content: Text('Are you sure you want to remove admin privileges from ${profile.name ?? profile.phoneNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FirestoreUserService().updateUserType(profile.uid, UserType.vip);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Admin role removed from ${profile.name ?? profile.phoneNumber}'
                : 'Failed to remove admin role. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// User Profile Dialog - Detailed user information
class UserProfileDialog extends StatelessWidget {
  final UserProfile profile;

  const UserProfileDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(profile.name ?? 'User Profile'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileField('Name', profile.name ?? 'Not provided'),
            _buildProfileField('Phone', profile.phoneNumber),
            _buildProfileField('Email', profile.email ?? 'Not provided'),
            _buildProfileField('User Type', profile.userType.displayName),
            _buildProfileField('Profile Complete', profile.isProfileComplete ? 'Yes' : 'No'),
            _buildProfileField('Joined', _formatFullDate(profile.createdAt)),
            if (profile.updatedAt != null)
              _buildProfileField('Last Updated', _formatFullDate(profile.updatedAt!)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showEditUserTypeDialog(context, profile);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
          child: const Text('Edit Type', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showEditUserTypeDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => EditUserTypeDialog(profile: profile),
    );
  }
}

/// Edit User Type Dialog - Change user type
class EditUserTypeDialog extends StatefulWidget {
  final UserProfile profile;

  const EditUserTypeDialog({super.key, required this.profile});

  @override
  State<EditUserTypeDialog> createState() => _EditUserTypeDialogState();
}

class _EditUserTypeDialogState extends State<EditUserTypeDialog> {
  late UserType _selectedUserType;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.profile.userType;
  }

  IconData _getIconForUserType(UserType type) {
    switch (type) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.premium:
        return Icons.diamond;
      case UserType.vip:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change User Type - ${widget.profile.name ?? widget.profile.phoneNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current type: ${widget.profile.userType.displayName}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserType>(
            value: _selectedUserType,
            decoration: const InputDecoration(
              labelText: 'New User Type',
              border: OutlineInputBorder(),
            ),
            items: UserType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getIconForUserType(type), color: type.color, size: 20),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUserType = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating || _selectedUserType == widget.profile.userType
              ? null
              : _updateUserType,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _updateUserType() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await FirestoreUserService().updateUserType(
        widget.profile.uid,
        _selectedUserType,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'User type updated to ${_selectedUserType.displayName}'
                : 'Failed to update user type. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Promote User Dialog - Search and promote user to admin
class PromoteUserDialog extends StatefulWidget {
  const PromoteUserDialog({super.key});

  @override
  State<PromoteUserDialog> createState() => _PromoteUserDialogState();
}

class _PromoteUserDialogState extends State<PromoteUserDialog> {
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promote User to Admin'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone number...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search for users'
                                : 'No users found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.userType.color.withOpacity(0.1),
                                child: Text(
                                  (user.name?.isNotEmpty == true ? user.name![0] : '?').toUpperCase(),
                                  style: TextStyle(
                                    color: user.userType.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(user.name ?? 'No Name'),
                              subtitle: Text(user.phoneNumber),
                              trailing: user.userType == UserType.admin
                                  ? const Chip(
                                      label: Text('Already Admin'),
                                      backgroundColor: Colors.orange,
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _promoteUser(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      child: const Text(
                                        'Promote',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final results = <UserProfile>[];
      for (final doc in snapshot.docs) {
        final profile = UserProfile.fromFirestore(doc);
        final name = profile.name?.toLowerCase() ?? '';
        final phone = profile.phoneNumber.toLowerCase();
        final searchQuery = query.toLowerCase();

        if (name.contains(searchQuery) || phone.contains(searchQuery)) {
          results.add(profile);
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _promoteUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Promotion'),
        content: Text('Promote ${user.name ?? user.phoneNumber} to Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Promote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FirestoreUserService().updateUserType(user.uid, UserType.admin);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '${user.name ?? user.phoneNumber} promoted to Admin!'
                : 'Failed to promote user. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}