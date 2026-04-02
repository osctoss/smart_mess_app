import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
          return;
        }

        final userData = doc.data();
        final userModel = UserModel(
          uid: user.uid,
          name: userData?['name'] ?? '',
          contactNumber: userData?['contactNumber'] ?? '',
          role: userData?['role'] ?? '',
          messId: userData?['messId'],
          approved: userData?['approved'] ?? false,
          createdAt: (userData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        if (!mounted) return;

        if (userModel.role == 'ADMIN') {
          if (userModel.messId == null) {
            Navigator.pushReplacementNamed(context, AppRoutes.createMess);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          }
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.scaffoldDark, Color(0xFF16162A), AppColors.scaffoldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with glow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // App name
              Text(
                'Smart Mess',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 36,
                  letterSpacing: -1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Your dining, simplified',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.accentOrange.withValues(alpha: 0.7),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
