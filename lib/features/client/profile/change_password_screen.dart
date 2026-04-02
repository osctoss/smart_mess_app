import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    oldPassController.dispose();
    newPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPassword = oldPassController.text.trim();
    final newPassword = newPassController.text.trim();

    final oldPasswordError = Validators.validatePassword(oldPassword);
    final newPasswordError = Validators.validatePassword(newPassword);

    if (oldPasswordError != null) {
      _showMessage(oldPasswordError);
      return;
    }

    if (newPasswordError != null) {
      _showMessage(newPasswordError);
      return;
    }

    if (oldPassword == newPassword) {
      _showMessage('New password must be different from old password.');
      return;
    }

    final user = _authService.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      _showMessage('Password update is unavailable for this account.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.reauthenticateWithEmailPassword(
        email: email,
        password: oldPassword,
      );
      await _authService.updatePassword(newPassword);

      oldPassController.clear();
      newPassController.clear();

      if (!mounted) return;
      _showMessage('Password updated successfully.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'wrong-password' ||
              e.code == 'invalid-credential'
          ? 'Old password is incorrect.'
          : (e.message ?? 'Failed to update password.');
      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to update password: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(controller: oldPassController, label: 'Old Password', obscureText: true),
            const SizedBox(height: 16),
            CustomTextField(controller: newPassController, label: 'New Password', obscureText: true),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Update Password',
              isLoading: _isLoading,
              onPressed: _updatePassword,
            ),
          ],
        ),
      ),
    );
  }
}
