import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

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

    setState(() => _isLoading = true);

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
      final message = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Old password is incorrect.'
          : (e.message ?? 'Failed to update password.');
      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.blueGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
            ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),
            Text('Update Password', style: AppTextStyles.heading3).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                children: [
                  CustomTextField(
                    controller: oldPassController,
                    label: 'Old Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: newPassController,
                    label: 'New Password',
                    prefixIcon: Icons.lock_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Update Password',
                    icon: Icons.save_rounded,
                    isLoading: _isLoading,
                    onPressed: _updatePassword,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
