import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_dashboard_controller.dart';
import '../../../core/routes/app_routes.dart';


class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardController(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AdminDashboardController>(
            builder: (_, controller, child) => Text(controller.mess?.messName ?? 'Admin Dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.adminNotifications);
              },
            ),
          ],
        ),
        body: Consumer<AdminDashboardController>(
          builder: (context, controller, _) {
             if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.mess == null) {
              return const Center(child: Text('Error loading mess details'));
            }

            return GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  title: 'Set Menu',
                  icon: Icons.restaurant_menu,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.menuManagement);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Members (${controller.totalMembers})',
                  icon: Icons.people,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.membersList);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Availability List',
                  icon: Icons.list_alt,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.availabilityList);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Attendance',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    // Navigator.pushNamed(context, AppRoutes.attendance);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
