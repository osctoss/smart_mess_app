import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Map<String, dynamic>? signupData; // null = login mode, non-null = signup mode

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.signupData,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Resend timer
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;
  
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: '+91${widget.phoneNumber}',
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!')),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      },
      onAutoVerified: (credential) async {
        // Auto-verification on resend
        await _signInWithCredential(credential);
      },
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credentials = await _authService.signInWithOTP(
        verificationId: _verificationId,
        otpCode: otp,
      );
      if (!mounted) return;
      _handleAuthSuccess(credentials);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithCredential(credential) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credentials = await _authService.signInWithPhoneCredential(credential);
      if (!mounted) return;
      _handleAuthSuccess(credentials);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isLoading = false;
      });
    }
  }

  void _handleAuthSuccess(credentials) {
    // Return the result to the calling screen (signup or login controller)
    Navigator.pop(context, credentials);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sms, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'OTP sent to +91 ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the 6-digit code sent to your phone',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _otpController,
              label: 'Enter OTP',
              keyboardType: TextInputType.number,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify OTP',
              onPressed: _verifyOTP,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _resendOTP,
                      child: const Text('Resend OTP'),
                    )
                  : Text(
                      'Resend OTP in ${_secondsRemaining}s',
                      style: const TextStyle(color: Colors.grey),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
