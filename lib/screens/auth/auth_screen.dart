import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/app_router.dart';

enum AuthStep { phoneInput, otpVerification }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  AuthStep _currentStep = AuthStep.phoneInput;
  bool _isLoading = false;
  String _verificationId = '';
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo and title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to Gita Connect',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your spiritual learning companion',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Auth form
              Form(
                key: _formKey,
                child: _currentStep == AuthStep.phoneInput
                    ? _buildPhoneInputStep()
                    : _buildOtpVerificationStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your mobile number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send you an OTP to verify your number',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        // Phone number input
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: const Icon(Icons.phone),
            prefixText: '+91 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            if (value.length != 10) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        
        // Send OTP button
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Send OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        
        const SizedBox(height: 24),
        
        // Skip for now (development purposes)
        TextButton(
          onPressed: () => _mockSuccessfulAuth(),
          child: const Text(
            'Skip for now (Demo)',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a 6-digit OTP to +91 ${_phoneController.text}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        // OTP input
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            hintText: '6-digit OTP',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 6) {
              return 'Please enter a valid 6-digit OTP';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        
        // Verify OTP button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Verify OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        
        const SizedBox(height: 24),
        
        // Back to phone input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = AuthStep.phoneInput;
                  _otpController.clear();
                });
              },
              child: const Text('← Back'),
            ),
            TextButton(
              onPressed: _resendOtp,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Firebase phone auth
      // For now, simulate OTP sending
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _currentStep = AuthStep.otpVerification;
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully! (Demo: use 123456)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Firebase OTP verification
      // For demo purposes, accept 123456 as valid OTP
      if (_otpController.text == '123456') {
        await _mockSuccessfulAuth();
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _mockSuccessfulAuth() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication success
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Create a mock user or implement proper authentication
    // For now, we'll just navigate to home
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }
}