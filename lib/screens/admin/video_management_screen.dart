import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/video_service.dart';

class VideoManagementScreen extends StatefulWidget {
  const VideoManagementScreen({super.key});

  @override
  State<VideoManagementScreen> createState() => _VideoManagementScreenState();
}

class _VideoManagementScreenState extends State<VideoManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'All';
  final Set<String> _selectedVideos = {};
  bool _isSelectionMode = false;

  final List<String> _videoCategories = [
    'Bhakti Bites', // For shorts
    'Lecture Videos', // For long lectures
    'Festival Videos',
    'Daily Programs',
    'Special Events',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Row(
          children: [
            Icon(Icons.video_library_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Video Management'),
          ],
        ),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.add), text: 'Add Video'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedVideos.isNotEmpty ? _deleteSelectedVideos : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedVideos.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                ),
              ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(),
          _buildAddVideoTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    return Column(
      children: [
        // Filter and Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All', _filterCategory == 'All'),
                    ..._videoCategories.map((category) =>
                        _buildCategoryChip(category, _filterCategory == category)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Selection Mode Info
        if (_isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_selectedVideos.length} video(s) selected',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedVideos.length < 10 ? _selectAllVisible : null,
                  child: const Text('Select All'),
                ),
              ],
            ),
          ),
        // Videos List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some videos to get started',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final videos = snapshot.data!.docs;
              
              // Filter videos based on selected category and search query
              final filteredVideos = videos.where((video) {
                final data = video.data() as Map<String, dynamic>;
                final category = data['category'] as String? ?? 'Other';
                final title = data['title'] as String? ?? '';
                final description = data['description'] as String? ?? '';
                
                // Category filter
                bool categoryMatch = _filterCategory == 'All' || category == _filterCategory;
                
                // Search filter
                bool searchMatch = _searchQuery.isEmpty || 
                    title.toLowerCase().contains(_searchQuery) ||
                    description.toLowerCase().contains(_searchQuery) ||
                    category.toLowerCase().contains(_searchQuery);
                
                return categoryMatch && searchMatch;
              }).toList();

              // Sort videos by createdAt (newest first)
              filteredVideos.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp? ?? Timestamp.now();
                final bTime = bData['createdAt'] as Timestamp? ?? Timestamp.now();
                return bTime.compareTo(aTime); // Descending order (newest first)
              });
              
              if (filteredVideos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos match your filters',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try changing the category or search terms',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterCategory = 'All';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredVideos.length,
                itemBuilder: (context, index) {
                  final video = filteredVideos[index];
                  final data = video.data() as Map<String, dynamic>;
                  final videoId = video.id;
                  
                  return _buildVideoCard(videoId, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterCategory = selected ? category : 'All';
          });
        },
        selectedColor: Colors.red.shade100,
        checkmarkColor: Colors.red.shade700,
      ),
    );
  }

  Widget _buildVideoCard(String videoId, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Untitled Video';
    final description = data['description'] as String? ?? '';
    final category = data['category'] as String? ?? 'Other';
    final url = data['url'] as String? ?? '';
    final thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
    final duration = data['duration'] as String? ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final isSelected = _selectedVideos.contains(videoId);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedVideos.remove(videoId);
            } else {
              _selectedVideos.add(videoId);
            }
          });
        } else {
          _showVideoDetails(videoId, data);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedVideos.add(videoId);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 3)
              : null,
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Video Thumbnail
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      if (thumbnailUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumbnailUrl,
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultThumbnail();
                            },
                          ),
                        )
                      else
                        _buildDefaultThumbnail(),
                      // Play button overlay
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      if (_isSelectionMode)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : null,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Video Details
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
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (duration.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Added: ${_formatDate(createdAt.toDate())}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Button
                if (!_isSelectionMode)
                  IconButton(
                    onPressed: () => _launchVideo(url),
                    icon: Icon(
                      Icons.play_circle_outline,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.video_library,
        color: Colors.red.shade400,
        size: 32,
      ),
    );
  }

  Widget _buildAddVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Video',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildAddVideoForm(),
        ],
      ),
    );
  }

  Widget _buildAddVideoForm() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final thumbnailUrlController = TextEditingController();
    final durationController = TextEditingController();
    String selectedCategory = 'Bhakti Bites';

    return StatefulBuilder(
      builder: (context, setFormState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video URL
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL *',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Video Title (Optional)',
                hintText: 'Leave empty to auto-fetch from YouTube',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Auto-fetch title from YouTube',
                  onPressed: () => _fetchTitleFromUrl(urlController, titleController),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter video description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _videoCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setFormState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Thumbnail URL
            TextField(
              controller: thumbnailUrlController,
              decoration: InputDecoration(
                labelText: 'Thumbnail URL (optional)',
                hintText: 'https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),
            
            // Duration
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Duration (optional)',
                hintText: 'e.g., 45:30 or 2:15',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addVideo(
                  titleController.text,
                  descriptionController.text,
                  urlController.text,
                  selectedCategory,
                  thumbnailUrlController.text,
                  durationController.text,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Video',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final videos = snapshot.data!.docs;
        final categoryStats = <String, int>{};

        for (final doc in videos) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String? ?? 'Other';
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              
              // Overview Stats
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Total Videos',
                      videos.length.toString(),
                      Icons.video_library,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Categories',
                      categoryStats.length.toString(),
                      Icons.category,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Category Breakdown
              if (categoryStats.isNotEmpty) ...[
                Text(
                  'Videos by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: categoryStats.entries.map((entry) {
                      final total = categoryStats.values.reduce((a, b) => a + b);
                      final percentage = (entry.value / total * 100).toStringAsFixed(1);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: entry.value / total,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: const AlwaysStoppedAnimation(Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _addVideo(
    String title,
    String description,
    String url,
    String category,
    String thumbnailUrl,
    String duration,
  ) async {
    // Only URL is required now
    if (url.trim().isEmpty) {
      _showErrorSnackBar('Please enter a YouTube URL');
      return;
    }

    // Validate YouTube URL
    if (!_isValidYouTubeUrl(url)) {
      _showErrorSnackBar('Please enter a valid YouTube URL');
      return;
    }

    try {
      // Auto-fetch title if not provided
      String finalTitle = title.trim();
      if (finalTitle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text('Fetching video title...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
        
        final fetchedTitle = await VideoService.fetchYouTubeTitle(url);
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (fetchedTitle != null && fetchedTitle.isNotEmpty) {
          finalTitle = fetchedTitle;
        } else {
          _showErrorSnackBar('Could not fetch video title. Please enter a title manually.');
          return;
        }
      }

      // Extract video ID and generate thumbnail if not provided
      String finalThumbnailUrl = thumbnailUrl.trim();
      if (finalThumbnailUrl.isEmpty) {
        final videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          finalThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }

      await FirebaseFirestore.instance.collection('videos').add({
        'title': finalTitle,
        'description': description.trim(),
        'url': url.trim(),
        'category': category,
        'thumbnailUrl': finalThumbnailUrl,
        'duration': duration.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin', // You can get actual admin user ID here
        'isActive': true,
      });

      _showSuccessSnackBar('Video added successfully!${finalTitle != title.trim() ? " (Title auto-fetched)" : ""}');
      
      // Switch to videos tab to see the new video
      _tabController.animateTo(0);
    } catch (e) {
      _showErrorSnackBar('Error adding video: $e');
    }
  }

  Future<void> _fetchTitleFromUrl(TextEditingController urlController, TextEditingController titleController) async {
    final url = urlController.text.trim();
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a YouTube URL first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_isValidYouTubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid YouTube URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text('Fetching video title...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );
    
    try {
      final title = await VideoService.fetchYouTubeTitle(url);
      
      // Clear any previous snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (title != null && title.isNotEmpty) {
        titleController.text = title;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Title fetched: ${title.length > 30 ? "${title.substring(0, 30)}..." : title}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not fetch title. Please enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error fetching title: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidYouTubeUrl(String url) {
    return url.contains('youtube.com/watch') || 
           url.contains('youtu.be/') || 
           url.contains('youtube.com/shorts');
  }

  String? _extractYouTubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})'
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _showVideoDetails(String videoId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => VideoDetailsDialog(
        videoId: videoId,
        videoData: data,
        categories: _videoCategories,
        onUpdate: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteSelectedVideos() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Videos'),
        content: Text('Are you sure you want to delete ${_selectedVideos.length} video(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        for (final videoId in _selectedVideos) {
          await FirebaseFirestore.instance.collection('videos').doc(videoId).delete();
        }
        
        setState(() {
          _selectedVideos.clear();
          _isSelectionMode = false;
        });
        
        _showSuccessSnackBar('Videos deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Error deleting videos: $e');
      }
    }
  }

  void _selectAllVisible() {
    // Implementation for selecting all visible videos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select all functionality coming soon!'),
      ),
    );
  }

  Future<void> _launchVideo(String url) async {
    try {
      final Uri videoUri = Uri.parse(url);
      await launchUrl(
        videoUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showErrorSnackBar('Could not open video: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

// Dialog for viewing and editing video details
class VideoDetailsDialog extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> videoData;
  final List<String> categories;
  final VoidCallback onUpdate;

  const VideoDetailsDialog({
    super.key,
    required this.videoId,
    required this.videoData,
    required this.categories,
    required this.onUpdate,
  });

  @override
  State<VideoDetailsDialog> createState() => _VideoDetailsDialogState();
}

class _VideoDetailsDialogState extends State<VideoDetailsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _thumbnailController;
  late TextEditingController _durationController;
  late String _selectedCategory;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.videoData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.videoData['description'] ?? '');
    _urlController = TextEditingController(text: widget.videoData['url'] ?? '');
    _thumbnailController = TextEditingController(text: widget.videoData['thumbnailUrl'] ?? '');
    _durationController = TextEditingController(text: widget.videoData['duration'] ?? '');
    _selectedCategory = widget.videoData['category'] ?? 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _thumbnailController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Video Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _deleteVideo,
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateVideo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateVideo() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'url': _urlController.text.trim(),
        'category': _selectedCategory,
        'thumbnailUrl': _thumbnailController.text.trim(),
        'duration': _durationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onUpdate();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteVideo() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('videos')
            .doc(widget.videoId)
            .delete();

        widget.onUpdate();
        Navigator.pop(context); // Close details dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}