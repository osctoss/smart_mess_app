import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'members_controller.dart';
import '../../../core/routes/app_routes.dart';


class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MembersController(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Members'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Approved'),
                Tab(text: 'Pending Request'),
              ],
            ),
          ),
          body: Consumer<MembersController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                 return const Center(child: CircularProgressIndicator());
              }
              
              return TabBarView(
                children: [
                  // Approved List
                  ListView.builder(
                    itemCount: controller.members.length,
                    itemBuilder: (context, index) {
                      final member = controller.members[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(member.name),
                        subtitle: Text(member.contactNumber),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => controller.removeMember(member.uid),
                        ),
                        onTap: () {
                           Navigator.pushNamed(context, AppRoutes.clientDetail, arguments: member);
                        },
                      );
                    },
                  ),
                  // Pending List
                  controller.errorMessage != null
                    ? Center(child: Text(controller.errorMessage!, style: const TextStyle(color: Colors.red)))
                    : controller.pendingMembers.isEmpty
                      ? const Center(child: Text('No pending requests'))
                      : ListView.builder(
                          itemCount: controller.pendingMembers.length,
                          itemBuilder: (context, index) {
                            final member = controller.pendingMembers[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                              title: Text(member.name),
                              subtitle: Text('Waiting for approval'),
                              trailing: ElevatedButton(
                                onPressed: () => controller.approveMember(member.uid),
                                child: const Text('Approve'),
                              ),
                            );
                          },
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
