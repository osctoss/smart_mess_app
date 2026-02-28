import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_mess_controller.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class CreateMessScreen extends StatelessWidget {
  const CreateMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateMessController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Mess')),
        body: Consumer<CreateMessController>(
          builder: (context, controller, _) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Setup Your Mess',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: controller.messNameController,
                    label: 'Mess Name',
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
                    text: 'Create Mess',
                    onPressed: () => controller.createMess(context),
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
