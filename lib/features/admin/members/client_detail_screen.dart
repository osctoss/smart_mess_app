import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../shared_widgets/glass_card.dart';
import '../../shared_widgets/gradient_scaffold.dart';

class ClientDetailScreen extends StatelessWidget {
  final UserModel? user;

  const ClientDetailScreen({super.key, this.user});

  Future<void> _updateDietBalance(
    BuildContext context, {
    required int amount,
    required bool isDeduction,
  }) async {
    if (user == null) return;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Amount')),
      );
      return;
    }

    try {
      final dietRef = FirebaseFirestore.instance
          .collection('dietBalances')
          .doc(user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final dietDoc = await transaction.get(dietRef);

        if (dietDoc.exists) {
          final data = dietDoc.data() ?? <String, dynamic>{};
          final currentTotal = (data['totalDiets'] ?? 0) as int;
          final currentRemaining = (data['remainingDiets'] ?? 0) as int;

          if (isDeduction) {
            if (currentRemaining < amount) {
              throw Exception('Not enough diets to deduct');
            }

            transaction.update(dietRef, {
              'remainingDiets': currentRemaining - amount,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(dietRef, {
              'totalDiets': currentTotal + amount,
              'remainingDiets': currentRemaining + amount,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        } else {
          if (isDeduction) {
            throw Exception('No diets available to deduct');
          }

          transaction.set(dietRef, {
            'uid': user!.uid,
            'totalDiets': amount,
            'remainingDiets': amount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get();
      final messId = adminDoc.data()?['messId'] ?? '';

      await NotificationService().sendNotification(
        messId: messId,
        type: isDeduction ? NotificationType.dietDeducted : NotificationType.dietAllocated,
        fromUid: adminUid,
        toUid: user!.uid,
        message: isDeduction ? '$amount diets deducted' : '$amount diets added',
      );

      // Notification for Admin
      await NotificationService().sendNotification(
        messId: messId,
        type: isDeduction ? NotificationType.dietDeducted : NotificationType.dietAllocated,
        fromUid: user!.uid,
        toUid: adminUid,
        message: isDeduction 
            ? 'You deducted $amount diets for ${user!.name}' 
            : 'You allocated $amount diets to ${user!.name}',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDeduction ? 'Diets Deducted' : 'Diets Added'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController dietController = TextEditingController();

    return GradientScaffold(
      appBar: AppBar(title: Text(user?.displayName ?? 'Client Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar header
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.blueGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (user?.name ?? 'U')[0].toUpperCase(),
                  style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 36),
                ),
              ),
            ).animate().scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),
            Text(user?.displayName ?? 'Name', style: AppTextStyles.heading2).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 4),
            Text(user?.contactNumber ?? 'Contact', style: AppTextStyles.subtitle).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Joined ${DateFormat('dd MMM yyyy').format(user?.createdAt ?? DateTime.now())}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ).animate().fadeIn(delay: 340.ms),

            const SizedBox(height: 36),

            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('dietBalances')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final totalDiets = (data?['totalDiets'] ?? 0) as int;
                final remainingDiets = (data?['remainingDiets'] ?? 0) as int;

                return GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.blueGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Current Diet Balance', style: AppTextStyles.heading4),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceStat(
                              label: 'Remaining',
                              value: '$remainingDiets',
                              valueColor: AppColors.accentTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BalanceStat(
                              label: 'Total',
                              value: '$totalDiets',
                              valueColor: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms);
              },
            ),

            const SizedBox(height: 16),

            // Diet allocation
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.tealGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Allocate Diet', style: AppTextStyles.heading4),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: dietController,
                    label: 'Number of Diets',
                    prefixIcon: Icons.add_circle_outline_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Add',
                          icon: Icons.add_rounded,
                          fullWidth: true,
                          onPressed: () async {
                            final amount = int.tryParse(dietController.text);
                            await _updateDietBalance(
                              context,
                              amount: amount ?? 0,
                              isDeduction: false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          text: 'Deduct',
                          icon: Icons.remove_rounded,
                          fullWidth: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentRose.withValues(alpha: 0.95),
                              AppColors.accentOrange.withValues(alpha: 0.95),
                            ],
                          ),
                          onPressed: () async {
                            final amount = int.tryParse(dietController.text);
                            await _updateDietBalance(
                              context,
                              amount: amount ?? 0,
                              isDeduction: true,
                            );
                          },
                        ),
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
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
