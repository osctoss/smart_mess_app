import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user == null
            ? null
            : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final profileData = snapshot.data?.data();
          final displayName = profileData?['name'] as String? ?? user?.email?.split('@')[0] ?? 'User';
          final createdAt = profileData?['createdAt'] is Timestamp
              ? (profileData!['createdAt'] as Timestamp).toDate()
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Avatar with gradient
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOrange.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 40),
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: AppTextStyles.heading2,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Joined ${DateFormat('dd MMM yyyy').format(createdAt)}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
                ],

                const SizedBox(height: 32),

                // Options
                _buildOptionCard(
                  icon: Icons.person_rounded,
                  iconGradient: AppColors.primaryGradient,
                  label: 'Change Name',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changeName),
                  index: 0,
                ),

                const SizedBox(height: 12),

                _buildOptionCard(
                  icon: Icons.lock_rounded,
                  iconGradient: AppColors.blueGradient,
                  label: 'Change Password',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                  index: 1,
                ),

                const SizedBox(height: 12),

                _buildOptionCard(
                  icon: Icons.phone_rounded,
                  iconGradient: AppColors.tealGradient,
                  label: 'Change Phone Number',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePhone),
                  index: 2,
                ),

                const SizedBox(height: 24),

                // Logout
                GlassCard(
                  onTap: () async {
                    await authService.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  },
                  borderColor: AppColors.accentRose.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.accentRose, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.accentRose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required LinearGradient iconGradient,
    required String label,
    required VoidCallback onTap,
    required int index,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 300 + index * 100), duration: 500.ms);
  }
}
