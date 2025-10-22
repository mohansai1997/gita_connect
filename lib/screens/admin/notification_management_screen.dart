import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_notification_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedTemplate; // Store selected template data
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  /// Use template - populate Send tab with template data
  void _useTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplate = template;
    });
    _tabController.animateTo(1); // Switch to Send tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Management',
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
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.send), text: 'Send'),
            Tab(icon: Icon(Icons.article), text: 'Templates'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotificationDashboardTab(tabController: _tabController),
          SendNotificationTab(selectedTemplate: _selectedTemplate),
          NotificationTemplatesTab(onUseTemplate: _useTemplate),
          const NotificationAnalyticsTab(),
        ],
      ),
    );
  }
}

/// Dashboard Tab - Overview and Quick Actions
class NotificationDashboardTab extends StatefulWidget {
  final TabController? tabController;
  
  const NotificationDashboardTab({super.key, this.tabController});

  @override
  State<NotificationDashboardTab> createState() => _NotificationDashboardTabState();
}

class _NotificationDashboardTabState extends State<NotificationDashboardTab> {
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> recentNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final [statsResult, notificationsResult] = await Future.wait([
        AdminNotificationService.getNotificationStats(),
        AdminNotificationService.getRecentNotifications(),
      ]);
      
      if (mounted) {
        setState(() {
          stats = statsResult as Map<String, dynamic>?;
          recentNotifications = notificationsResult as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview
            _buildStatsOverview(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Recent Notifications
            _buildRecentNotifications(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sent',
                stats!['totalNotifications'].toString(),
                Icons.send,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Week',
                stats!['thisWeekCount'].toString(),
                Icons.calendar_today,
                Colors.green,
              ),
            ),
          ],
        ),

      ],
    );
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Switch to Send tab
                  widget.tabController?.animateTo(1);
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Switch to Templates tab
                  widget.tabController?.animateTo(2);
                },
                icon: const Icon(Icons.article),
                label: const Text('Manage Templates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Test Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test (to yourself)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sendTestToAllUsers,
                icon: const Icon(Icons.send),
                label: const Text('Test to ALL Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // FCM Configuration Test
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _testFCMConfiguration,
            icon: const Icon(Icons.settings),
            label: const Text('Test FCM Configuration (for closed apps)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final success = await AdminNotificationService.sendImmediateNotification(
        title: 'Test Notification 🧪',
        body: 'This is a test notification to verify the system is working correctly!',
        targetAudience: 'All Users',
        priority: 'High',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent successfully! Check your notifications.'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the dashboard data
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send test notification. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestToAllUsers() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to ALL Users'),
        content: const Text(
          'This will send a test notification to ALL users in the app. '
          'Are you sure you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send to All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await AdminNotificationService.sendImmediateNotification(
        title: 'Test Broadcast 📢',
        body: 'This is a test notification sent to ALL users. If you received this, the system is working perfectly!',
        targetAudience: 'All Users',
        priority: 'High',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast notification sent to all users! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the dashboard data
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send broadcast notification. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending broadcast notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testFCMConfiguration() async {
    try {
      // First show instructions if needed
      final testResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM Configuration Test'),
          content: const Text(
            'This will test if FCM push notifications are properly configured. '
            'These notifications work even when the app is closed.\n\n'
            'Note: If you haven\'t configured the Firebase Server Key yet, '
            'you\'ll only get Firestore-based notifications (app must be open).'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Test FCM'),
            ),
          ],
        ),
      );

      if (testResult != true) return;

      // Import FCMPushService and test it
      final success = await AdminNotificationService.testFCMConfiguration();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM configuration test completed! Check your notifications.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'FCM test completed. If you didn\'t receive a push notification, '
              'you may need to configure the Firebase Server Key.'
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Instructions',
              textColor: Colors.white,
              onPressed: () {
                _showFCMInstructions();
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing FCM: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFCMInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FCM Setup Instructions'),
        content: const SingleChildScrollView(
          child: Text(
            'To enable push notifications when app is closed:\n\n'
            '1. Go to Firebase Console\n'
            '2. Select your "gita-connect" project\n'
            '3. Go to Project Settings (gear icon)\n'
            '4. Click "Cloud Messaging" tab\n'
            '5. Copy the "Server key"\n'
            '6. Replace YOUR_FIREBASE_SERVER_KEY_HERE in fcm_push_service.dart\n\n'
            'Without this key, notifications only work when app is open.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Switch to Analytics tab
                DefaultTabController.of(context).animateTo(3);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentNotifications.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications sent yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send your first notification to get started',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentNotifications.map((notification) => _buildNotificationCard(notification)),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final sentAt = notification['sentAt'] as Timestamp?;
    final timeAgo = sentAt != null 
        ? _getTimeAgo(sentAt.toDate())
        : 'Unknown time';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.shade100,
          child: Icon(
            Icons.notifications,
            color: Colors.deepOrange.shade700,
          ),
        ),
        title: Text(
          notification['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['body'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification['status'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${notification['recipientCount'] ?? 0} recipients',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Send Notification Tab - Create and Send Notifications
class SendNotificationTab extends StatefulWidget {
  final Map<String, dynamic>? selectedTemplate;
  
  const SendNotificationTab({super.key, this.selectedTemplate});

  @override
  State<SendNotificationTab> createState() => _SendNotificationTabState();
}

class _SendNotificationTabState extends State<SendNotificationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String _selectedAudience = 'All Users';
  String _selectedPriority = 'Normal';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _populateFromTemplate();
  }
  
  @override
  void didUpdateWidget(SendNotificationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTemplate != oldWidget.selectedTemplate) {
      _populateFromTemplate();
    }
  }
  
  void _populateFromTemplate() {
    if (widget.selectedTemplate != null) {
      final template = widget.selectedTemplate!;
      _titleController.text = template['title'] ?? '';
      _bodyController.text = template['body'] ?? '';
      // Show success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "${template['name']}" loaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Notification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title *',
                hintText: 'Enter notification title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Body Field
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message Body *',
                hintText: 'Enter notification message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Target Audience
            DropdownButtonFormField<String>(
              value: _selectedAudience,
              decoration: const InputDecoration(
                labelText: 'Target Audience',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items: const [
                DropdownMenuItem(value: 'All Users', child: Text('All Users')),
                DropdownMenuItem(value: 'Admins Only', child: Text('Admins Only')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAudience = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Priority
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSending
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sending...'),
                        ],
                      )
                    : const Text(
                        'Send Notification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final success = await AdminNotificationService.sendImmediateNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetAudience: _selectedAudience,
        priority: _selectedPriority,
      );

      if (success) {
        _showSuccessSnackBar('Notification sent successfully!');
        _clearForm();
      } else {
        _showErrorSnackBar('Failed to send notification. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending notification: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _selectedAudience = 'All Users';
      _selectedPriority = 'Normal';
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Templates Tab - Manage Notification Templates
class NotificationTemplatesTab extends StatefulWidget {
  final Function(Map<String, dynamic>) onUseTemplate;
  
  const NotificationTemplatesTab({super.key, required this.onUseTemplate});

  @override
  State<NotificationTemplatesTab> createState() => _NotificationTemplatesTabState();
}

class _NotificationTemplatesTabState extends State<NotificationTemplatesTab> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      print('UI: Loading templates...');
      final loadedTemplates = await AdminNotificationService.getTemplates();
      print('UI: Received ${loadedTemplates.length} templates from service');
      
      if (mounted) {
        setState(() {
          templates = loadedTemplates;
          isLoading = false;
        });
        print('UI: Templates state updated with ${templates.length} items');
      }
    } catch (e) {
      print('UI ERROR loading templates: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Add Template button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification Templates',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateTemplateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Templates List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : templates.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTemplates,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          return _buildTemplateCard(templates[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No templates found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first template to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTemplateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    template['name'] ?? 'Untitled Template',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'use') {
                      _useTemplate(template);
                    } else if (value == 'delete') {
                      _deleteTemplate(template['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'use',
                      child: Row(
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 8),
                          Text('Use Template'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                template['category'] ?? 'General',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              template['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template['body'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTemplateDialog(
        onTemplateCreated: _loadTemplates,
      ),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    // Use the callback to pass template data to parent and switch tabs
    widget.onUseTemplate(template);
  }

  Future<void> _deleteTemplate(String templateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminNotificationService.deleteTemplate(templateId);
      if (success) {
        _loadTemplates();
        _showSuccessSnackBar('Template deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete template');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Analytics Tab - Notification History and Statistics
class NotificationAnalyticsTab extends StatefulWidget {
  const NotificationAnalyticsTab({super.key});

  @override
  State<NotificationAnalyticsTab> createState() => _NotificationAnalyticsTabState();
}

class _NotificationAnalyticsTabState extends State<NotificationAnalyticsTab> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final history = await AdminNotificationService.getNotificationHistory();
      if (mounted) {
        setState(() {
          notifications = history;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadNotificationHistory,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // History List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotificationHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationHistoryCard(notifications[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications sent yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your notification history will appear here',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryCard(Map<String, dynamic> notification) {
    final sentAt = notification['sentAt'] as Timestamp?;
    final dateStr = sentAt != null
        ? '${sentAt.toDate().day}/${sentAt.toDate().month}/${sentAt.toDate().year}'
        : 'Unknown date';
    final timeStr = sentAt != null
        ? '${sentAt.toDate().hour.toString().padLeft(2, '0')}:${sentAt.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notification['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(notification['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification['status'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(notification['status']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification['body'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${notification['recipientCount'] ?? 0} recipients',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$dateStr at $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Create Template Dialog
class CreateTemplateDialog extends StatefulWidget {
  final VoidCallback onTemplateCreated;

  const CreateTemplateDialog({
    super.key,
    required this.onTemplateCreated,
  });

  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Template'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name *',
                  hintText: 'e.g., Daily Krishna Reminder',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a template name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'Daily Spiritual', child: Text('Daily Spiritual')),
                  DropdownMenuItem(value: 'Festivals', child: Text('Festivals')),
                  DropdownMenuItem(value: 'Content Updates', child: Text('Content Updates')),
                  DropdownMenuItem(value: 'Spiritual Quotes', child: Text('Spiritual Quotes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message Body *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createTemplate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final success = await AdminNotificationService.createTemplate(
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        category: _selectedCategory,
      );

      if (success) {
        Navigator.pop(context);
        // Add a small delay before refreshing to ensure Firestore write completes
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onTemplateCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create template. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating template: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
}