import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Map<String, dynamic>? signupData;

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
  final List<TextEditingController> _digitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
    // Auto-focus first digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _digitControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _digitControllers.map((c) => c.text).join();

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
        await _signInWithCredential(credential);
      },
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpCode;
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
    Navigator.pop(context, credentials);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Shield icon with glow
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.blueGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded, size: 40, color: Colors.white),
            ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text(
              'Verification Code',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 8),
            Text(
              'Code sent to +91 ${widget.phoneNumber}',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 36),

            // OTP digit boxes
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) => _buildDigitBox(index)),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentRose),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 28),

                  CustomButton(
                    text: 'Verify',
                    icon: Icons.check_circle_rounded,
                    onPressed: _verifyOTP,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 20),

                  // Resend section
                  _canResend
                      ? TextButton.icon(
                          onPressed: _resendOTP,
                          icon: Icon(Icons.refresh_rounded, color: AppColors.accentOrange, size: 18),
                          label: Text('Resend OTP', style: AppTextStyles.accentBody),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: _secondsRemaining / 60,
                                strokeWidth: 2,
                                color: AppColors.accentAmber,
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Resend in ${_secondsRemaining}s',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.heading2.copyWith(fontSize: 22),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: _digitControllers[index].text.isNotEmpty
              ? AppColors.accentOrange.withOpacity(0.1)
              : AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _digitControllers[index].text.isNotEmpty
                  ? AppColors.accentOrange.withOpacity(0.5)
                  : AppColors.glassBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {}); // Refresh styling
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-verify when all 6 digits entered
          if (_otpCode.length == 6) {
            _verifyOTP();
          }
        },
      ),
    );
  }
}
