import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static const String _profileKey = 'user_profile';

  // Save user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      final result = await prefs.setString(_profileKey, profileJson);
      
      if (kDebugMode) {
        debugPrint('Profile saved: ${profile.toString()}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving profile: $e');
      }
      return false;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson == null) {
        if (kDebugMode) {
          debugPrint('No profile found');
        }
        return null;
      }
      
      final profileMap = json.decode(profileJson) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(profileMap);
      
      if (kDebugMode) {
        debugPrint('Profile loaded: ${profile.toString()}');
      }
      
      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading profile: $e');
      }
      return null;
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
      final existingProfile = await getUserProfile();
      
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
      final profile = UserProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        name: null,
        email: null,
        isProfileComplete: false,
        createdAt: DateTime.now(),
        updatedAt: null,
      );
      
      return await saveUserProfile(profile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating initial profile: $e');
      }
      return false;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final profile = await getUserProfile();
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking profile completion: $e');
      }
      return false;
    }
  }

  // Clear profile (for logout)
  Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_profileKey);
      
      if (kDebugMode) {
        debugPrint('Profile cleared');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing profile: $e');
      }
      return false;
    }
  }

  // Get user name
  Future<String?> getUserName() async {
    final profile = await getUserProfile();
    return profile?.name;
  }

  // Get user email
  Future<String?> getUserEmail() async {
    final profile = await getUserProfile();
    return profile?.email;
  }
}