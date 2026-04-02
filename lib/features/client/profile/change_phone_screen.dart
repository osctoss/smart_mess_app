import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

class ChangePhoneScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  ChangePhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Change Phone Number')),
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
                gradient: AppColors.tealGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 32),
            ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),
            Text('Update Phone', style: AppTextStyles.heading3).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                children: [
                  CustomTextField(
                    controller: phoneController,
                    label: 'New Phone Number',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Verify & Update',
                    icon: Icons.verified_rounded,
                    onPressed: () {
                      // Implement OTP verification and update logic
                    },
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
