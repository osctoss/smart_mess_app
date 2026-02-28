import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client_dashboard_controller.dart';
import '../../../core/routes/app_routes.dart';

// import '../../shared_widgets/diet_counter_widget.dart'; // Create later
// import '../../shared_widgets/menu_card_widget.dart'; // Create later

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientDashboardController(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<ClientDashboardController>(
            builder: (_, controller, child) => Text(controller.mess?.messName ?? 'Dashboard'),
          ),
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
        body: Consumer<ClientDashboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.user?.messId == null) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.selectMess);
                  },
                  child: const Text('Join a Mess'),
                ),
              );
            }

            if (controller.user != null && !controller.user!.approved) {
               return const Center(
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.access_time, size: 64, color: Colors.orange),
                         SizedBox(height: 16),
                         Text(
                           'Waiting for Approval',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         Text('Please contact your mess admin.'),
                      ],
                   ),
                 ),
               );
            }

            return RefreshIndicator(
              onRefresh: () async => controller.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Diet Counter Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Diet Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '${controller.dietBalance?.remainingDiets ?? 0} / ${controller.dietBalance?.totalDiets ?? 0}',
                              style: const TextStyle(fontSize: 32, color: Colors.blue),
                            ),
                            const Text('Remaining / Total'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Menu Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Today\'s Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Divider(),
                            const Text('Morning:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(controller.todayMenu?.morningMenu ?? 'Not set'),
                            const SizedBox(height: 8),
                            const Text('Evening:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(controller.todayMenu?.eveningMenu ?? 'Not set'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Availability Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Manage Availability'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.clientAvailability);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
