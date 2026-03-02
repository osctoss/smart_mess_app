import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'attendance_controller.dart';
import '../../../core/constants/enums.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: Consumer<AttendanceController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                // Date Picker
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => controller.onDateSelected(controller.selectedDate.subtract(const Duration(days: 1))),
                      ),
                      Text(DateFormat('yyyy-MM-dd').format(controller.selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => controller.onDateSelected(controller.selectedDate.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
                // Meal Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Morning'),
                      selected: controller.selectedMeal == MealType.morning,
                      onSelected: (bool selected) {
                        if (selected) controller.setMealType(MealType.morning);
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Evening'),
                      selected: controller.selectedMeal == MealType.evening,
                      onSelected: (bool selected) {
                        if (selected) controller.setMealType(MealType.evening);
                      },
                    ),
                  ],
                ),
                const Divider(),
                if (controller.isLoading)
                  const LinearProgressIndicator()
                else
                  Expanded(
                    child: controller.availableMembers.isEmpty
                        ? const Center(child: Text('No available members'))
                        : ListView.builder(
                            itemCount: controller.availableMembers.length,
                            itemBuilder: (context, index) {
                              final user = controller.availableMembers[index];
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(user.name),
                                subtitle: Text(user.contactNumber),
                                trailing: const Icon(Icons.check_circle, color: Colors.green),
                              );
                            },
                          ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Text(
                    'Total Present: ${controller.availableMembers.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
