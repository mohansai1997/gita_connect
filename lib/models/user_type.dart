import 'package:flutter/material.dart';

/// User Type Enum for Gita Connect App
/// Defines different user tiers with their access levels
enum UserType {
  admin('Admin', 'Full administrative access'),
  vip('VIP', 'Premium content access'), 
  premium('Premium', 'Exclusive paid features');

  const UserType(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Convert string to UserType enum
  /// Returns VIP as default for unknown values
  static UserType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'vip':
        return UserType.vip;
      case 'premium':
        return UserType.premium;
      default:
        return UserType.vip; // Default for new users
    }
  }

  /// Convert UserType to string for database storage
  @override
  String toString() => name;

  /// Check if user has admin privileges
  bool get isAdmin => this == UserType.admin;

  /// Check if user has VIP or higher access
  bool get hasVipAccess => this == UserType.vip || this == UserType.admin;

  /// Check if user has premium features
  bool get hasPremiumAccess => this == UserType.premium || this == UserType.admin;

  /// Get user type priority (higher number = higher access)
  int get priority {
    switch (this) {
      case UserType.admin:
        return 3;
      case UserType.premium:
        return 2;
      case UserType.vip:
        return 1;
    }
  }

  /// Compare user types by priority
  bool operator >(UserType other) => priority > other.priority;
  bool operator <(UserType other) => priority < other.priority;
  bool operator >=(UserType other) => priority >= other.priority;
  bool operator <=(UserType other) => priority <= other.priority;

  /// Get icon for the user type
  String get icon {
    switch (this) {
      case UserType.admin:
        return '👑'; // Crown for admin
      case UserType.premium:
        return '💎'; // Diamond for premium
      case UserType.vip:
        return '⭐'; // Star for VIP
    }
  }

  /// Get color associated with user type
  String get colorHex {
    switch (this) {
      case UserType.admin:
        return '#FF6B35'; // Deep Orange (admin powers)
      case UserType.premium:
        return '#9C27B0'; // Purple (premium exclusivity)
      case UserType.vip:
        return '#FF9800'; // Orange (VIP treatment)
    }
  }

  /// Get Flutter Color object for user type
  Color get color {
    switch (this) {
      case UserType.admin:
        return const Color(0xFFFF6B35); // Deep Orange (admin powers)
      case UserType.premium:
        return const Color(0xFF9C27B0); // Purple (premium exclusivity)
      case UserType.vip:
        return const Color(0xFFFF9800); // Orange (VIP treatment)
    }
  }
}