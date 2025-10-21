import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class VideoService {
  static const String _collection = 'videos';

  /// Get videos by category
  static Future<List<Map<String, dynamic>>> getVideosByCategory(String category) async {
    try {
      print('DEBUG: Getting videos for category: $category');
      
      // Simple query without orderBy to avoid index requirement
      final query = FirebaseFirestore.instance
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();
      
      print('DEBUG: Found ${snapshot.docs.length} videos for category $category');
      
      final results = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        print('DEBUG: Video: ${data['title']} - Category: ${data['category']}');
        return data;
      }).toList();
      
      // Sort in memory instead of in query
      results.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order (newest first)
      });
      
      return results;
    } catch (e) {
      print('ERROR getting videos by category $category: $e');
      return [];
    }
  }

  /// Get Bhakti Bites (shorts)
  static Future<List<Map<String, dynamic>>> getBhaktiBites() async {
    return getVideosByCategory('Bhakti Bites');
  }

  /// Get Lecture Videos
  static Future<List<Map<String, dynamic>>> getLectureVideos() async {
    return getVideosByCategory('Lecture Videos');
  }

  /// Get all available categories that have at least one video
  static Future<List<String>> getAvailableCategories() async {
    try {
      print('DEBUG: Getting all available categories with videos');
      
      final query = FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();
      
      final Set<String> categories = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      final result = categories.toList()..sort();
      print('DEBUG: Found categories with videos: $result');
      return result;
    } catch (e) {
      print('ERROR getting available categories: $e');
      return [];
    }
  }

  /// Get all active videos
  static Future<List<Map<String, dynamic>>> getAllVideos() async {
    try {
      print('DEBUG: Getting all active videos');
      
      // Simple query without orderBy to avoid index requirement
      final query = FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();
      
      print('DEBUG: Found ${snapshot.docs.length} total active videos');
      
      final results = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        print('DEBUG: Video: ${data['title']} - Category: ${data['category']} - Active: ${data['isActive']}');
        return data;
      }).toList();
      
      // Sort in memory instead of in query
      results.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order (newest first)
      });
      
      return results;
    } catch (e) {
      print('ERROR getting all videos: $e');
      return [];
    }
  }

  /// Stream of videos for real-time updates
  static Stream<List<Map<String, dynamic>>> getVideosStream(String? category) {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error getting videos stream: $e');
      return Stream.value([]);
    }
  }

  /// Add a new video
  static Future<bool> addVideo({
    required String title,
    required String url,
    required String category,
    String? description,
    String? thumbnailUrl,
    String? duration,
  }) async {
    try {
      // Extract video ID and generate thumbnail if not provided
      String finalThumbnailUrl = thumbnailUrl ?? '';
      if (finalThumbnailUrl.isEmpty) {
        final videoId = extractYouTubeVideoId(url);
        if (videoId != null) {
          finalThumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }

      await FirebaseFirestore.instance.collection(_collection).add({
        'title': title.trim(),
        'description': description?.trim() ?? '',
        'url': url.trim(),
        'category': category,
        'thumbnailUrl': finalThumbnailUrl,
        'duration': duration?.trim() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return true;
    } catch (e) {
      print('Error adding video: $e');
      return false;
    }
  }

  /// Update video
  static Future<bool> updateVideo(
    String videoId, {
    String? title,
    String? description,
    String? url,
    String? category,
    String? thumbnailUrl,
    String? duration,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (title != null) updates['title'] = title.trim();
      if (description != null) updates['description'] = description.trim();
      if (url != null) updates['url'] = url.trim();
      if (category != null) updates['category'] = category;
      if (thumbnailUrl != null) updates['thumbnailUrl'] = thumbnailUrl.trim();
      if (duration != null) updates['duration'] = duration.trim();
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(videoId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating video: $e');
      return false;
    }
  }

  /// Delete video
  static Future<bool> deleteVideo(String videoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(videoId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  /// Extract YouTube video ID from URL
  static String? extractYouTubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})'
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Validate YouTube URL
  static bool isValidYouTubeUrl(String url) {
    return url.contains('youtube.com/watch') || 
           url.contains('youtu.be/') || 
           url.contains('youtube.com/shorts');
  }

  /// Convert any YouTube URL to standard watch URL
  static String convertToStandardUrl(String url) {
    final videoId = extractYouTubeVideoId(url);
    if (videoId != null) {
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    return url; // Return original if conversion fails
  }

  /// Get video statistics
  static Future<Map<String, int>> getVideoStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final stats = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Other';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting video stats: $e');
      return {};
    }
  }

  /// Debug method to check all videos in database
  static Future<void> debugAllVideos() async {
    try {
      print('=== DEBUG: Checking all videos in database ===');
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .get();

      print('Total documents in videos collection: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Video ID: ${doc.id}');
        print('  Title: ${data['title']}');
        print('  Category: ${data['category']}');
        print('  isActive: ${data['isActive']}');
        print('  URL: ${data['url']}');
        print('  Created: ${data['createdAt']}');
        print('---');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('ERROR in debugAllVideos: $e');
    }
  }

  /// Fetch video title from YouTube URL
  static Future<String?> fetchYouTubeTitle(String url) async {
    try {
      print('DEBUG: Fetching title for URL: $url');
      
      // Make HTTP request to get the webpage content
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final htmlContent = response.body;
        
        // Extract title from HTML using regex
        // Look for <title> tag or og:title meta tag
        RegExp titleRegex = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true);
        Match? titleMatch = titleRegex.firstMatch(htmlContent);
        
        if (titleMatch != null) {
          String title = titleMatch.group(1) ?? '';
          
          // Clean up YouTube title (remove " - YouTube" suffix)
          title = title.replaceAll(RegExp(r'\s*-\s*YouTube\s*$'), '');
          title = title.trim();
          
          // Decode HTML entities
          title = title
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");
          
          print('DEBUG: Extracted title: $title');
          return title.isNotEmpty ? title : null;
        }
        
        // Fallback: try og:title meta tag
        RegExp ogTitleRegex = RegExp(r'<meta[^>]*property=["\x27]og:title["\x27][^>]*content=["\x27]([^"\x27]*)["\x27]', caseSensitive: false);
        Match? ogMatch = ogTitleRegex.firstMatch(htmlContent);
        
        if (ogMatch != null) {
          String title = ogMatch.group(1) ?? '';
          title = title.trim();
          print('DEBUG: Extracted OG title: $title');
          return title.isNotEmpty ? title : null;
        }
      } else {
        print('ERROR: HTTP ${response.statusCode} when fetching $url');
      }
    } catch (e) {
      print('ERROR fetching YouTube title: $e');
    }
    
    return null;
  }
}