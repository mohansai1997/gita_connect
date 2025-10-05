import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Test mode flag for emulator
  bool _testModeAuthenticated = false;
  
  // Method to clear test mode authentication
  void clearTestMode() {
    if (kDebugMode) {
      _testModeAuthenticated = false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null || (kDebugMode && _testModeAuthenticated);

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verify phone number and send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
  }) async {
    // Test mode for emulator - bypass Firebase if network issues
    if (kDebugMode && phoneNumber == '+911234567890') {
      debugPrint('Test mode: Simulating OTP send for test number');
      // Simulate a successful OTP send for testing
      codeSent('test_verification_id', null);
      return;
    }

    try {
      // Additional attempt to disable reCAPTCHA before each phone verification
      try {
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
          forceRecaptchaFlow: false,
        );
        debugPrint('Firebase Auth settings configured to avoid reCAPTCHA');
      } catch (e) {
        debugPrint('Warning: Could not set Firebase Auth settings: $e');
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 120), // Increased timeout
      );
    } catch (e) {
      debugPrint('Error in phone verification: $e');
      // If verification fails due to reCAPTCHA, try alternative approach
      if (e.toString().contains('captcha') || e.toString().contains('verification')) {
        debugPrint('reCAPTCHA detected, you may need to add SHA-256 fingerprint to Firebase Console');
      }
      rethrow;
    }
  }

  // Verify OTP and sign in
  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    // Test mode for emulator - only for the specific test number
    if (kDebugMode && verificationId == 'test_verification_id') {
      debugPrint('Test mode: Validating test OTP for test number only');
      // Accept test OTP codes for testing
      if (smsCode == '123456' || smsCode == '000000' || smsCode.length == 6) {
        // Create a mock user for testing
        debugPrint('Test mode: OTP verified successfully, simulating login');
        _testModeAuthenticated = true;
        return true;
      } else {
        debugPrint('Test mode: Invalid test OTP');
        return false;
      }
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error verifying OTP: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error verifying OTP: $e');
      return false;
    }
  }

  // Sign in with credential (for auto-verification)
  Future<bool> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing in with credential: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error signing in: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear test mode authentication
      clearTestMode();
      
      debugPrint('User signed out successfully');
      // Note: Firestore profile data persists across sign-ins
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get user phone number
  String? getUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  // Get user UID
  String? getUserUID() {
    return _auth.currentUser?.uid;
  }
}