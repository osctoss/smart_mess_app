import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/enums.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class ClientDetailScreen extends StatelessWidget {
  final UserModel? user; // Passed via arguments

  const ClientDetailScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
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

                    // Send diet allocation notification to the client
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
