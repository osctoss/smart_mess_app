import 'package:flutter/material.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

// Placeholder logic
class ChangePasswordScreen extends StatelessWidget {
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();

  ChangePasswordScreen({super.key});

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
            CustomButton(text: 'Update Password', onPressed: () {
              // Implement update logic using AuthService/Firebase Auth
            }),
          ],
        ),
      ),
    );
  }
}
