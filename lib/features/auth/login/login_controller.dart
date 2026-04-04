import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/user_model.dart';

class LoginController with ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> login(BuildContext context) async {
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

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

    try {
      // Login using email/password (phone@smartmess.com pattern)
      final email = '$contact@smartmess.com';
      final credentials = await _authService.signInWithEmail(email: email, password: password);

      // Fetch user doc to check role
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credentials.user!.uid)
          .get();

      if (!doc.exists) {
        _errorMessage = 'User data not found. Please contact admin.';
        await _authService.signOut();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = doc.data();
      final userModel = UserModel(
        uid: credentials.user!.uid,
        name: userData?['name'] ?? '',
        contactNumber: userData?['contactNumber'] ?? '',
        role: userData?['role'] ?? '',
        messId: userData?['messId'],
        approved: userData?['approved'] ?? false,
        createdAt: (userData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      if (!context.mounted) return;

      if (userModel.role == 'ADMIN') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Invalid phone number or password.';
      } else {
        _errorMessage = e.message ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
