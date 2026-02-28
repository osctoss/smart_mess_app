import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'select_mess_controller.dart';

import '../../../models/mess_model.dart'; // Import model

class SelectMessScreen extends StatelessWidget {
  const SelectMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectMessController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Select a Mess')),
        body: Consumer<SelectMessController>(
          builder: (context, controller, _) {
            return StreamBuilder<List<MessModel>>(
              stream: controller.messesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messes = snapshot.data ?? [];

                if (messes.isEmpty) {
                  return const Center(child: Text('No messes found.'));
                }

                return ListView.builder(
                  itemCount: messes.length,
                  itemBuilder: (context, index) {
                    final mess = messes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(mess.messName),
                        subtitle: Text('Admin: ${mess.createdBy}'), // Maybe fetch admin name later
                        trailing: ElevatedButton(
                          onPressed: () => controller.joinMess(context, mess),
                          child: const Text('Join'),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
