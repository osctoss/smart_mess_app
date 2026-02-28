import 'package:flutter/material.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

// Placeholder logic
class ChangePhoneScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  ChangePhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             CustomTextField(controller: phoneController, label: 'New Phone Number', keyboardType: TextInputType.phone),
             const SizedBox(height: 24),
             CustomButton(text: 'Verify & Update', onPressed: () {
               // Implement OTP verification and update logic
             }),
          ],
        ),
      ),
    );
  }
}
