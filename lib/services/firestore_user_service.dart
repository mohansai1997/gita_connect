import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class FirestoreUserService {
  static final FirestoreUserService _instance = FirestoreUserService._internal();
  factory FirestoreUserService() => _instance;
  FirestoreUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('Fetching profile for UID: $uid');
      }

      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          debugPrint('No profile found for UID: $uid');
        }
        return null;
      }

      final profile = UserProfile.fromFirestore(docSnapshot);
      
      if (kDebugMode) {
        debugPrint('Profile loaded from Firestore: ${profile.toString()}');
      }
      
      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading profile from Firestore: $e');
      }
      return null;
    }
  }

  // Save user profile to Firestore
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      if (kDebugMode) {
        debugPrint('Saving profile to Firestore: ${profile.toString()}');
      }

      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profile.toFirestore());

      if (kDebugMode) {
        debugPrint('Profile saved successfully to Firestore');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving profile to Firestore: $e');
      }
      return false;
    }
  }

  // Update user profile with name and email
  Future<bool> updateProfile({
    required String uid,
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Updating profile for UID: $uid');
      }

      // Get existing profile to preserve createdAt
      final existingProfile = await getUserProfile(uid);
      
      final updatedProfile = UserProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        isProfileComplete: true,
        createdAt: existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating profile: $e');
      }
      return false;
    }
  }

  // Create initial profile for new user
  Future<bool> createInitialProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Creating initial profile for UID: $uid');
      }

      // Check if profile already exists
      final existingProfile = await getUserProfile(uid);
      if (existingProfile != null) {
        if (kDebugMode) {
          debugPrint('Profile already exists for UID: $uid');
        }
        return true; // Profile already exists, consider it successful
      }

      final profile = UserProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        name: null,
        email: null,
        isProfileComplete: false,
        createdAt: DateTime.now(),
        updatedAt: null,
      );
      
      final success = await saveUserProfile(profile);
      
      // Add a small delay to ensure Firestore write is complete
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (kDebugMode) {
          debugPrint('Initial profile created and saved to Firestore');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating initial profile: $e');
      }
      return false;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking profile completion: $e');
      }
      return false;
    }
  }

  // Get user name
  Future<String?> getUserName(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.name;
  }

  // Get user email
  Future<String?> getUserEmail(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.email;
  }

  // Delete user profile (for account deletion)
  Future<bool> deleteUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('Deleting profile for UID: $uid');
      }

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .delete();

      if (kDebugMode) {
        debugPrint('Profile deleted successfully from Firestore');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting profile from Firestore: $e');
      }
      return false;
    }
  }

  // Listen to profile changes (for real-time updates)
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((docSnapshot) {
      if (!docSnapshot.exists) return null;
      try {
        return UserProfile.fromFirestore(docSnapshot);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing profile from stream: $e');
        }
        return null;
      }
    });
  }

  // Batch operation - useful for future bulk operations
  Future<bool> batchUpdateProfiles(List<UserProfile> profiles) async {
    try {
      final batch = _firestore.batch();
      
      for (final profile in profiles) {
        final docRef = _firestore.collection(_usersCollection).doc(profile.uid);
        batch.set(docRef, profile.toFirestore());
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('Batch update completed for ${profiles.length} profiles');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in batch update: $e');
      }
      return false;
    }
  }
}