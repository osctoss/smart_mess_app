import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/routes/app_routes.dart';
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
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // User exists in Auth but not in Firestore? Should likely logout or go to specialized setup.
          // For now, logout and go to login to be safe.
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
          // CLIENT — always go to home hub
          Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
        }
      } catch (e) {
        // Handle error (e.g., offline)
        // Ensure to navigate somewhere or show error retry
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        // Maybe stay on splash with a retry button? or go to login
        // develop retry logic later. for now, let's just show error.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Smart Mess App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
