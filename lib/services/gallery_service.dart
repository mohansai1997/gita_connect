import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _galleryFolderPath = 'gallery';

  // Fetch all photos from gallery folder
  Future<List<String>> getGalleryPhotos() async {
    try {
      debugPrint('Fetching photos from Firebase Storage gallery folder...');
      
      // Get reference to gallery folder
      final ListResult result = await _storage.ref(_galleryFolderPath).listAll();
      
      debugPrint('Found ${result.items.length} photos in gallery folder');
      
      // Get download URLs for all images
      final List<String> photoUrls = [];
      
      for (Reference ref in result.items) {
        try {
          final String downloadUrl = await ref.getDownloadURL();
          photoUrls.add(downloadUrl);
          debugPrint('Added photo: ${ref.name}');
        } catch (e) {
          debugPrint('Error getting URL for ${ref.name}: $e');
        }
      }
      
      debugPrint('Successfully retrieved ${photoUrls.length} photo URLs');
      return photoUrls;
      
    } catch (e) {
      debugPrint('Error fetching gallery photos: $e');
      return [];
    }
  }

  // Get photo metadata (optional - for future use)
  Future<Map<String, dynamic>?> getPhotoMetadata(String photoPath) async {
    try {
      final Reference ref = _storage.ref('$_galleryFolderPath/$photoPath');
      final FullMetadata metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'contentType': metadata.contentType,
      };
    } catch (e) {
      debugPrint('Error getting metadata for $photoPath: $e');
      return null;
    }
  }

  // Upload photo to gallery (for future admin functionality)
  Future<bool> uploadPhoto(String localPath, String fileName) async {
    try {
      debugPrint('Uploading photo: $fileName to $_galleryFolderPath');
      
      // This would be implemented when adding photo upload functionality
      // final Reference ref = _storage.ref('$_galleryFolderPath/$fileName');
      // final UploadTask uploadTask = ref.putFile(File(localPath));
      // await uploadTask;
      
      debugPrint('Photo upload method ready for implementation');
      return true;
      
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return false;
    }
  }
}