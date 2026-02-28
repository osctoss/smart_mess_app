import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_controller.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/enums.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupController(),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.signup)),
        body: Consumer<SignupController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: controller.nameController,
                    label: 'Can You Tell Ur Name',
                  ),
                  const SizedBox(height: 16),
                  // Phone number with country code prefix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '+91',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: controller.contactController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: controller.passwordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Role:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.setRole(UserRole.client),
                          child: Row(
                            children: [
                              Radio<UserRole>(
                                value: UserRole.client,
                                groupValue: controller.selectedRole,
                                onChanged: (value) => controller.setRole(value!),
                              ),
                              const Text('Client'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.setRole(UserRole.admin),
                          child: Row(
                            children: [
                              Radio<UserRole>(
                                value: UserRole.admin,
                                groupValue: controller.selectedRole,
                                onChanged: (value) => controller.setRole(value!),
                              ),
                              const Text('Admin'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Send OTP & Sign Up',
                    onPressed: () => controller.sendOTP(context),
                    isLoading: controller.isLoading,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
