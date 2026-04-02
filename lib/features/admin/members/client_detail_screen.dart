import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  Widget build(BuildContext context) {
    final TextEditingController dietController = TextEditingController();

    return GradientScaffold(
      appBar: AppBar(title: Text(user?.name ?? 'Client Detail')),
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
            Text(user?.name ?? 'Name', style: AppTextStyles.heading2).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 4),
            Text(user?.contactNumber ?? 'Contact', style: AppTextStyles.subtitle).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 36),

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
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: dietController,
                          label: 'Number of Diets',
                          prefixIcon: Icons.add_circle_outline_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          text: 'Add',
                          icon: Icons.add_rounded,
                          fullWidth: true,
                          onPressed: () async {
                            final amount = int.tryParse(dietController.text);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid Amount')),
                              );
                              return;
                            }

                            try {
                              final dietRef = FirebaseFirestore.instance
                                  .collection('dietBalances')
                                  .doc(user!.uid);
                              final dietDoc = await dietRef.get();

                              if (dietDoc.exists) {
                                await dietRef.update({
                                  'totalDiets': FieldValue.increment(amount),
                                  'remainingDiets': FieldValue.increment(amount),
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                });
                              } else {
                                await dietRef.set({
                                  'uid': user!.uid,
                                  'totalDiets': amount,
                                  'remainingDiets': amount,
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                });
                              }

                              final adminUid = FirebaseAuth.instance.currentUser!.uid;
                              final adminDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(adminUid)
                                  .get();
                              final messId = adminDoc.data()?['messId'] ?? '';

                              await NotificationService().sendNotification(
                                messId: messId,
                                type: NotificationType.dietAllocated,
                                fromUid: adminUid,
                                toUid: user!.uid,
                                message: '$amount diets added',
                              );

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Diets Added')),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
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
