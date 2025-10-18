import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _selectedCategory = 'Temple Events'; // For upload default
  String _filterCategory = 'All'; // For filtering photos
  String _searchQuery = ''; // For search functionality
  final Set<String> _selectedPhotos = {};
  bool _isSelectionMode = false;
  int _currentUploadIndex = 0;
  int _totalUploads = 0;

  final List<String> _categories = [
    'Temple Events',
    'Festivals',
    'Daily Darshan',
    'Spiritual Programs',
    'Community Service',
    'Youth Programs',
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
            Icon(Icons.photo_library_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Gallery Management'),
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
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.cloud_upload), text: 'Upload'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedPhotos.isNotEmpty ? _deleteSelectedPhotos : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedPhotos.clear();
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
          _buildPhotosTab(),
          _buildUploadTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
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
                  hintText: 'Search photos...',
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
                    ..._categories.map((category) =>
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
                  '${_selectedPhotos.length} photo(s) selected',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedPhotos.length < 10 ? _selectAllVisible : null,
                  child: const Text('Select All'),
                ),
              ],
            ),
          ),
        // Photos Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gallery')
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
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No photos in gallery',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload some photos to get started',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final photos = snapshot.data!.docs;
              
              // Sort photos manually to handle missing uploadedAt fields
              photos.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['uploadedAt'] as Timestamp?;
                final bTime = bData['uploadedAt'] as Timestamp?;
                
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1; // Put photos without dates at the end
                if (bTime == null) return -1;
                return bTime.compareTo(aTime); // Descending order
              });
              
              // Filter photos based on selected category and search query
              final filteredPhotos = photos.where((photo) {
                final data = photo.data() as Map<String, dynamic>;
                final category = data['category'] as String? ?? 'Other';
                final title = data['title'] as String? ?? data['name'] as String? ?? '';
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
              
              // Show no results message if filtered list is empty
              if (filteredPhotos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _filterCategory != 'All' || _searchQuery.isNotEmpty 
                            ? Icons.filter_list_off 
                            : Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterCategory != 'All' || _searchQuery.isNotEmpty
                            ? 'No photos match your filters'
                            : 'No photos in gallery',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filterCategory != 'All' || _searchQuery.isNotEmpty
                            ? 'Try changing the category or search terms'
                            : 'Upload some photos to get started',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_filterCategory != 'All' || _searchQuery.isNotEmpty) ...[
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
                    ],
                  ),
                );
              }
              
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredPhotos.length,
                itemBuilder: (context, index) {
                  final photo = filteredPhotos[index];
                  final data = photo.data() as Map<String, dynamic>;
                  final photoId = photo.id;
                  
                  // Try multiple possible field names for image URL
                  final imageUrl = data['imageUrl'] as String? ?? 
                                  data['url'] as String? ?? 
                                  data['image'] as String? ?? 
                                  data['downloadUrl'] as String? ?? '';
                  
                  final title = data['title'] as String? ?? 
                               data['name'] as String? ?? 
                               'Photo ${index + 1}';
                  final category = data['category'] as String? ?? 'Other';
                  final uploadedAt = data['uploadedAt'] as Timestamp? ?? 
                                    data['createdAt'] as Timestamp? ?? 
                                    data['timestamp'] as Timestamp?;
                  final isSelected = _selectedPhotos.contains(photoId);

                  // Skip photos without valid image URL
                  if (imageUrl.isEmpty) {
                    return Container(); // Return empty container for invalid photos
                  }

                  return _buildPhotoCard(
                    photoId,
                    imageUrl,
                    title,
                    category,
                    uploadedAt?.toDate(),
                    isSelected,
                  );
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

  Widget _buildPhotoCard(
    String photoId,
    String imageUrl,
    String title,
    String category,
    DateTime? uploadedAt,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedPhotos.remove(photoId);
            } else {
              _selectedPhotos.add(photoId);
            }
          });
        } else {
          _showPhotoDetails(photoId, imageUrl, title, category, uploadedAt);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedPhotos.add(photoId);
          });
        }
      },
      child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        top: 8,
                        right: 8,
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (uploadedAt != null)
                        Text(
                          _formatDate(uploadedAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Progress
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Uploading photos...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.blue.shade100,
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalUploads > 0 
                        ? 'Uploading photo $_currentUploadIndex of $_totalUploads...'
                        : '${(_uploadProgress * 100).toInt()}% complete',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Upload Options
          Text(
            'Upload New Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Upload Buttons
          Row(
            children: [
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.photo_camera,
                  title: 'Take Photo',
                  subtitle: 'Use camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.photo_library,
                  title: 'From Gallery',
                  subtitle: 'Pick from device',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildUploadOption(
            icon: Icons.photo_library_outlined,
            title: 'Multiple Photos',
            subtitle: 'Select multiple photos at once',
            onTap: _pickMultipleImages,
          ),

          const SizedBox(height: 32),

          // Upload Settings
          Text(
            'Upload Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Category Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _categories.map((category) {
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Storage Usage
          _buildStorageUsage(),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isUploading ? Colors.grey.shade100 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isUploading ? Colors.grey.shade300 : Colors.red.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: _isUploading ? Colors.grey : Colors.red.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isUploading ? Colors.grey : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: _isUploading ? Colors.grey : Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageUsage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final totalPhotos = snapshot.data!.docs.length;
        // Estimate storage usage (this would be more accurate with actual file sizes)
        final estimatedStorageMB = totalPhotos * 2; // Assume 2MB per photo

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Storage Usage',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Photos: $totalPhotos'),
                  Text('~${estimatedStorageMB}MB used'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final photos = snapshot.data!.docs;
        final categoryStats = <String, int>{};
        final monthlyUploads = <String, int>{};

        for (final doc in photos) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String? ?? 'Other';
          final uploadedAt = data['uploadedAt'] as Timestamp?;

          // Category stats
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;

          // Monthly stats
          if (uploadedAt != null) {
            final monthKey = '${uploadedAt.toDate().month}/${uploadedAt.toDate().year}';
            monthlyUploads[monthKey] = (monthlyUploads[monthKey] ?? 0) + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Stats
              _buildAnalyticsOverview(photos.length, categoryStats),
              const SizedBox(height: 24),

              // Category Breakdown
              _buildCategoryAnalytics(categoryStats),
              const SizedBox(height: 24),

              // Upload Trends
              _buildUploadTrends(monthlyUploads),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsOverview(int totalPhotos, Map<String, int> categoryStats) {
    // Handle case where there are no categories
    final mostPopularCategory = categoryStats.isNotEmpty 
        ? categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b)
        : const MapEntry('No categories', 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Photos',
                totalPhotos.toString(),
                Icons.photo_library,
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
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          'Most Popular Category',
          '${mostPopularCategory.key} (${mostPopularCategory.value})',
          Icons.star,
          Colors.orange,
        ),
      ],
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

  Widget _buildCategoryAnalytics(Map<String, int> categoryStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos by Category',
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
    );
  }

  Widget _buildUploadTrends(Map<String, int> monthlyUploads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Trends',
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
            children: monthlyUploads.entries.take(6).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value} photos',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        // Show dialog for custom title and description
        final metadata = await _showPhotoMetadataDialog();
        if (metadata != null) {
          await _uploadPhoto(image, customTitle: metadata['title'], customDescription: metadata['description']);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      // Use FilePicker for true multi-selection like WhatsApp
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowCompression: true,
      );
      
      if (result == null || result.files.isEmpty) {
        return; // User cancelled or no files selected
      }
      
      // Filter only valid image files with paths
      final validFiles = result.files.where((file) => 
        file.path != null && 
        file.path!.isNotEmpty &&
        _isImageFile(file.extension)
      ).toList();
      
      if (validFiles.isEmpty) {
        _showErrorSnackBar('No valid image files selected');
        return;
      }
      
      // Convert to XFile for consistency with existing upload logic
      final List<XFile> images = validFiles
          .map((file) => XFile(file.path!))
          .toList();
      
      // Show confirmation dialog with selection summary
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.photo_library, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Ready to Upload'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${images.length} photo(s) selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Category: $_selectedCategory',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated time: ${_estimateUploadTime(images.length)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All photos will be uploaded to the "$_selectedCategory" category.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload, size: 16),
                  const SizedBox(width: 6),
                  const Text('Upload All'),
                ],
              ),
            ),
          ],
        ),
      );
      
      if (shouldUpload != true) return;
      
      // Start bulk upload process
      setState(() {
        _totalUploads = images.length;
        _currentUploadIndex = 0;
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      int successfulUploads = 0;
      int failedUploads = 0;
      final List<String> failedFiles = [];

      for (int i = 0; i < images.length; i++) {
        setState(() {
          _currentUploadIndex = i + 1;
          _uploadProgress = i / images.length;
        });
        
        try {
          await _uploadPhoto(images[i], showIndividualSuccess: false);
          successfulUploads++;
        } catch (e) {
          failedUploads++;
          failedFiles.add(images[i].name);
          print('Failed to upload image ${i + 1}: $e');
        }
      }

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _currentUploadIndex = 0;
        _totalUploads = 0;
      });

      // Show detailed result summary
      if (failedUploads == 0) {
        _showSuccessSnackBar('🎉 All $successfulUploads photos uploaded successfully!');
      } else if (successfulUploads == 0) {
        _showErrorSnackBar('❌ Failed to upload all photos. Please check your internet connection and try again.');
      } else {
        // Show detailed dialog for partial success
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text('$successfulUploads photos uploaded successfully'),
                  ],
                ),
                if (failedUploads > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text('$failedUploads photos failed'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Failed files:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...failedFiles.take(5).map((file) => Text('• $file', style: TextStyle(fontSize: 12))),
                  if (failedFiles.length > 5)
                    Text('• ... and ${failedFiles.length - 5} more', style: TextStyle(fontSize: 12)),
                ],
              ],
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
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _currentUploadIndex = 0;
        _totalUploads = 0;
      });
      _showErrorSnackBar('Error selecting images: $e');
    }
  }

  bool _isImageFile(String? extension) {
    if (extension == null) return false;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  String _estimateUploadTime(int photoCount) {
    if (photoCount <= 5) return '< 1 minute';
    if (photoCount <= 10) return '1-2 minutes';
    if (photoCount <= 20) return '2-5 minutes';
    if (photoCount <= 50) return '5-10 minutes';
    return '10+ minutes';
  }

  Future<void> _uploadPhoto(XFile image, {bool showIndividualSuccess = true, String? customTitle, String? customDescription}) async {
    if (!_isUploading && showIndividualSuccess) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('gallery')
          .child(fileName);

      final File file = File(image.path);
      final UploadTask uploadTask = storageRef.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (showIndividualSuccess || _totalUploads <= 1) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Generate a meaningful title based on current date and category
      final now = DateTime.now();
      final String autoTitle = customTitle ?? _generatePhotoTitle(_selectedCategory, now);

      // Save to Firestore with comprehensive metadata
      await FirebaseFirestore.instance.collection('gallery').add({
        'imageUrl': downloadUrl,
        'title': autoTitle,
        'category': _selectedCategory,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileName': fileName,
        'fileSize': await file.length(),
        'uploadedBy': 'admin', // You can get actual admin user ID here
        'description': customDescription ?? '', // Can be edited later
        'tags': [], // Can be added later
        'isVisible': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (showIndividualSuccess) {
        _showSuccessSnackBar('Photo uploaded successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading photo: $e');
    } finally {
      if (showIndividualSuccess) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  String _generatePhotoTitle(String category, DateTime date) {
    final month = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][date.month];
    
    switch (category) {
      case 'Temple Events':
        return 'Temple Event - $month ${date.day}, ${date.year}';
      case 'Festivals':
        return 'Festival - $month ${date.day}, ${date.year}';
      case 'Daily Darshan':
        return 'Daily Darshan - $month ${date.day}, ${date.year}';
      case 'Spiritual Programs':
        return 'Spiritual Program - $month ${date.day}, ${date.year}';
      case 'Community Service':
        return 'Community Service - $month ${date.day}, ${date.year}';
      case 'Youth Programs':
        return 'Youth Program - $month ${date.day}, ${date.year}';
      default:
        return 'Photo - $month ${date.day}, ${date.year}';
    }
  }

  Future<Map<String, String>?> _showPhotoMetadataDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'Auto-generated if empty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add photo description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  void _showPhotoDetails(String photoId, String imageUrl, String title, String category, DateTime? uploadedAt) {
    // First, let's get the raw document data for debugging
    FirebaseFirestore.instance.collection('gallery').doc(photoId).get().then((doc) {
      if (doc.exists) {
        final rawData = doc.data() as Map<String, dynamic>;
        print('=== DEBUG: Photo $photoId fields ===');
        rawData.forEach((key, value) {
          print('$key: $value (${value.runtimeType})');
        });
        print('=== END DEBUG ===');
      }
    });

    showDialog(
      context: context,
      builder: (context) => PhotoDetailsDialog(
        photoId: photoId,
        imageUrl: imageUrl,
        title: title,
        category: category,
        uploadedAt: uploadedAt,
        categories: _categories,
        onUpdate: () {
          // Refresh the photos list
          setState(() {});
        },
      ),
    );
  }

  void _selectAllVisible() {
    // This would select all currently visible photos
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select all functionality coming soon!'),
      ),
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${_selectedPhotos.length} photo(s)?'),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove the photos from both the database and storage.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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
        int successfulDeletes = 0;
        int failedDeletes = 0;
        final List<String> failedPhotoIds = [];

        for (final photoId in _selectedPhotos) {
          try {
            // First, get the document to retrieve storage info
            final doc = await FirebaseFirestore.instance
                .collection('gallery')
                .doc(photoId)
                .get();

            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              
              // Try to get storage reference info
              final imageUrl = data['imageUrl'] as String?;
              final fileName = data['fileName'] as String?;
              
              // Delete from Firebase Storage
              if (imageUrl != null && imageUrl.isNotEmpty) {
                try {
                  // Method 1: Delete using the full URL
                  final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                  await ref.delete();
                } catch (urlError) {
                  // Method 2: Delete using fileName if URL method fails
                  if (fileName != null && fileName.isNotEmpty) {
                    try {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('gallery')
                          .child(fileName);
                      await ref.delete();
                    } catch (fileNameError) {
                      print('Failed to delete from storage using fileName: $fileNameError');
                    }
                  }
                }
              }
            }

            // Delete from Firestore (always attempt this)
            await FirebaseFirestore.instance
                .collection('gallery')
                .doc(photoId)
                .delete();

            successfulDeletes++;
          } catch (e) {
            failedDeletes++;
            failedPhotoIds.add(photoId);
            print('Failed to delete photo $photoId: $e');
          }
        }
        
        setState(() {
          _selectedPhotos.clear();
          _isSelectionMode = false;
        });
        
        // Show appropriate success/error message
        if (failedDeletes == 0) {
          _showSuccessSnackBar('All $successfulDeletes photos deleted successfully!');
        } else if (successfulDeletes == 0) {
          _showErrorSnackBar('Failed to delete all photos. Please try again.');
        } else {
          _showSuccessSnackBar('$successfulDeletes photos deleted, $failedDeletes failed to delete completely.');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting photos: $e');
      }
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

class PhotoDetailsDialog extends StatefulWidget {
  final String photoId;
  final String imageUrl;
  final String title;
  final String category;
  final DateTime? uploadedAt;
  final List<String> categories;
  final VoidCallback onUpdate;

  const PhotoDetailsDialog({
    super.key,
    required this.photoId,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.uploadedAt,
    required this.categories,
    required this.onUpdate,
  });

  @override
  State<PhotoDetailsDialog> createState() => _PhotoDetailsDialogState();
}

class _PhotoDetailsDialogState extends State<PhotoDetailsDialog> {
  late TextEditingController _titleController;
  late String _selectedCategory;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Photo Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
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
            const SizedBox(height: 16),
            
            // Upload Date
            if (widget.uploadedAt != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Uploaded: ${widget.uploadedAt!.day}/${widget.uploadedAt!.month}/${widget.uploadedAt!.year}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
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
          onPressed: _deletePhoto,
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updatePhoto,
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

  Future<void> _updatePhoto() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('gallery')
          .doc(widget.photoId)
          .update({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onUpdate();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deletePhoto() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this photo?'),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove the photo from both the database and storage.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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
        // First, get the document to retrieve storage info
        final doc = await FirebaseFirestore.instance
            .collection('gallery')
            .doc(widget.photoId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Try to get storage reference info
          final imageUrl = data['imageUrl'] as String?;
          final fileName = data['fileName'] as String?;
          
          // Delete from Firebase Storage first
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              // Method 1: Delete using the full URL
              final ref = FirebaseStorage.instance.refFromURL(imageUrl);
              await ref.delete();
            } catch (urlError) {
              // Method 2: Delete using fileName if URL method fails
              if (fileName != null && fileName.isNotEmpty) {
                try {
                  final ref = FirebaseStorage.instance
                      .ref()
                      .child('gallery')
                      .child(fileName);
                  await ref.delete();
                } catch (fileNameError) {
                  print('Failed to delete from storage using fileName: $fileNameError');
                  // Continue to delete from Firestore even if storage deletion fails
                }
              }
            }
          }
        }

        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('gallery')
            .doc(widget.photoId)
            .delete();

        widget.onUpdate();
        Navigator.pop(context); // Close details dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}