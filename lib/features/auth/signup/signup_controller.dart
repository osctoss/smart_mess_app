import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/device_id_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../otp/otp_screen.dart';

class SignupController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DeviceIdService _deviceIdService = DeviceIdService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.client;
  UserRole get selectedRole => _selectedRole;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> sendOTP(BuildContext context) async {
    final name = nameController.text.trim();
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty) {
      _errorMessage = 'Name is required';
      notifyListeners();
      return;
    }

    final contactError = Validators.validatePhone(contact);
    final passwordError = Validators.validatePassword(password);

    if (contactError != null || passwordError != null) {
      _errorMessage = contactError ?? passwordError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final phoneNumber = '+91$contact';

    try {
      final deviceId = await _deviceIdService.getDeviceId();
      await _authService.reserveOtpRequest(
        deviceId: deviceId,
        phoneNumber: phoneNumber,
      );

      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) async {
          _isLoading = false;
          notifyListeners();

          if (!context.mounted) return;

          // Navigate to OTP screen and wait for result
          final result = await Navigator.push<UserCredential>(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
                verificationId: verificationId,
                phoneNumber: contact,
              ),
            ),
          );

          if (!context.mounted) return;
          if (result != null && result.user != null) {
            await _completeSignup(context, result.user!, name, contact, password);
          }
        },
        onError: (errorMessage) {
          _isLoading = false;
          _errorMessage = errorMessage;
          notifyListeners();
        },
        onAutoVerified: (credential) async {
          try {
            final result = await _authService.signInWithPhoneCredential(credential);
            _isLoading = false;
            notifyListeners();
            if (result.user != null) {
              if (!context.mounted) return;
              await _completeSignup(context, result.user!, name, contact, password);
            }
          } catch (e) {
            _isLoading = false;
            _errorMessage = 'Auto-verification failed: $e';
            notifyListeners();
          }
        },
      );
    } on FirebaseFunctionsException catch (e) {
      _isLoading = false;
      _errorMessage = e.message ?? 'OTP request failed.';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Phone verification error: $e';
      notifyListeners();
    }
  }

  Future<void> _completeSignup(
    BuildContext context,
    User firebaseUser,
    String name,
    String contact,
    String password,
  ) async {
    try {
      // Link email/password credential FIRST so user can login with password later.
      // This MUST succeed before we create the Firestore user document.
      final email = '$contact@smartmess.com';
      try {
        await _authService.linkEmailPassword(email: email, password: password);
      } catch (e) {
        // If linking fails, delete the phone-auth user to avoid orphaned accounts
        await firebaseUser.delete();
        _errorMessage = 'Failed to set up password login: $e';
        notifyListeners();
        return;
      }

      await _authService.createUserProfile(
        uid: firebaseUser.uid,
        name: name,
        contactNumber: contact,
        role: _selectedRole == UserRole.admin ? 'ADMIN' : 'CLIENT',
      );

      if (!context.mounted) return;

      // Navigate based on role
      if (_selectedRole == UserRole.admin) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminHome, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } on FirebaseFunctionsException catch (e) {
      await _authService.signOut();
      try {
        await firebaseUser.delete();
      } catch (_) {}
      _errorMessage = e.message ?? 'Signup failed.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to create account: $e';
      notifyListeners();
    }
  }
}
