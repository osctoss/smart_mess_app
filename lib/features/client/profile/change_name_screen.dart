import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  final AuthService _authService = AuthService();
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String _initialName = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _initialName = (user?.displayName ?? '').trim();
    _nameController = TextEditingController(text: _initialName);
    _loadCurrentName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final firestoreName = (snapshot.data()?['name'] as String? ?? '').trim();
      if (!mounted || firestoreName.isEmpty) return;

      _initialName = firestoreName;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = firestoreName;
      }
    } catch (_) {
      // Keep the screen usable even if the prefill lookup fails.
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    final validationError = Validators.validateName(newName);

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final currentName = _initialName.isNotEmpty
        ? _initialName
        : (user?.displayName ?? '').trim();
    if (newName == currentName) {
      _showMessage('Please enter a different name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateDisplayName(newName);
      _initialName = newName;
      if (!mounted) return;
      _showMessage('Name updated successfully.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message ?? 'Failed to update name.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to update name: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return GradientScaffold(
      appBar: AppBar(title: const Text('Change Name')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
            ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Update Name', style: AppTextStyles.heading3).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'This updates the name shown across your profile and dashboards.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'New Name',
                    prefixIcon: Icons.badge_rounded,
                    hintText: 'Enter your full name',
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Update Name',
                    icon: Icons.save_rounded,
                    isLoading: _isLoading,
                    onPressed: _updateName,
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
