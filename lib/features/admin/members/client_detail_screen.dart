import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class ClientDetailScreen extends StatelessWidget {
  final UserModel? user; // Passed via arguments

  const ClientDetailScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    // In real app, fetch fresh data using user.uid
    final TextEditingController dietController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(user?.name ?? 'Client Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user?.contactNumber ?? 'Contact'),
            const SizedBox(height: 32),
            const Text('Allocate Diet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: dietController, label: 'Number of Diets', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                CustomButton(text: 'Add', onPressed: () async {
                  final amount = int.tryParse(dietController.text);
                  if (amount == null || amount <= 0) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Amount')));
                     return;
                  }
                  
                  // Update Diet Balance
                  // Use FirestoreService to increment (could be transaction, but simplified here)
                  // We need to READ first to get current, or use FieldValue.increment if supported by our service wrapper.
                  // Our wrapper 'updateData' takes a map. Firestore supports FieldValue.increment.
                  
                  try {
                    await FirestoreService().updateData(
                      path: 'dietBalances/${user!.uid}', 
                      data: {
                        'totalDiets': FieldValue.increment(amount),
                        'remainingDiets': FieldValue.increment(amount),
                        'lastUpdated': FieldValue.serverTimestamp(),
                      }
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diets Added')));
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }),
              ],
            )
          ],
        ),
      ),
    );
  }
}
