import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String phoneNumber;
  final String? name;
  final String? email;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    this.name,
    this.email,
    required this.isProfileComplete,
    required this.createdAt,
    this.updatedAt,
  });

  // Create UserProfile from JSON (for SharedPreferences compatibility)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'],
      email: json['email'],
      isProfileComplete: json['isProfileComplete'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Create UserProfile from Firestore DocumentSnapshot
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('No data found in Firestore document');
    }
    
    return UserProfile(
      uid: data['uid'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'],
      email: data['email'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert UserProfile to JSON (for SharedPreferences compatibility)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Convert UserProfile to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    String? email,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile{uid: $uid, phoneNumber: $phoneNumber, name: $name, email: $email, isProfileComplete: $isProfileComplete}';
  }
}