import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client_home_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/mess_model.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientHomeController(),
      child: Consumer<ClientHomeController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.clientNotifications);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.clientProfile);
                  },
                ),
              ],
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => controller.refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Greeting
                          Text(
                            'Welcome, ${controller.user?.name ?? 'User'}!',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),

                          // Joined Mess Section
                          _buildJoinedMessSection(context, controller),

                          const SizedBox(height: 24),

                          // Available Messes
                          const Text(
                            'Available Messes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildMessList(context, controller),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildJoinedMessSection(BuildContext context, ClientHomeController controller) {
    if (controller.user?.messId == null || controller.joinedMess == null) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'You haven\'t joined any mess yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Select one from the list below',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // User has joined a mess
    final isApproved = controller.user!.approved;

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: isApproved
            ? () => Navigator.pushNamed(context, AppRoutes.clientDashboard)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 40,
                color: isApproved ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.joinedMess!.messName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isApproved ? 'Tap to open dashboard' : 'Waiting for admin approval...',
                      style: TextStyle(
                        color: isApproved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isApproved) const Icon(Icons.arrow_forward_ios, size: 16),
              if (!isApproved) const Icon(Icons.access_time, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessList(BuildContext context, ClientHomeController controller) {
    return StreamBuilder<List<MessModel>>(
      stream: controller.messesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allMesses = snapshot.data ?? [];

        // Exclude the mess the user already joined
        final messes = allMesses
            .where((m) => m.messId != controller.user?.messId)
            .toList();

        if (messes.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No other messes available')),
            ),
          );
        }

        // Disable join buttons if user already has a mess
        final hasJoinedMess = controller.user?.messId != null;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messes.length,
          itemBuilder: (context, index) {
            final mess = messes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                title: Text(mess.messName),
                trailing: hasJoinedMess
                    ? null
                    : ElevatedButton(
                        onPressed: () => controller.joinMess(context, mess),
                        child: const Text('Join'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
