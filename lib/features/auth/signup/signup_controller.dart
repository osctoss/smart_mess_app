import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../otp/otp_screen.dart';

class SignupController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

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
      // Check if user doc already exists
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (existingDoc.exists) {
        _errorMessage = 'An account with this phone number already exists. Please login instead.';
        notifyListeners();
        await _authService.signOut();
        return;
      }

      // Link email/password credential so user can login with password later
      final email = '$contact@smartmess.com';
      await _authService.linkEmailPassword(email: email, password: password);

      // Store user in Firestore
      await _firestoreService.setData(
        path: 'users/${firebaseUser.uid}',
        data: {
          'uid': firebaseUser.uid,
          'name': name,
          'contactNumber': contact,
          'role': _selectedRole == UserRole.admin ? 'ADMIN' : 'CLIENT',
          'messId': null,
          'approved': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      if (!context.mounted) return;

      // Navigate based on role
      if (_selectedRole == UserRole.admin) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.createMess, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.selectMess, (route) => false);
      }
    } catch (e) {
      _errorMessage = 'Failed to create account: $e';
      notifyListeners();
    }
  }
}
