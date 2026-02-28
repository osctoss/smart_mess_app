import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'availability_controller.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvailabilityController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: Consumer<AvailabilityController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 30)),
                  lastDay: DateTime.now().add(const Duration(days: 30)),
                  focusedDay: controller.selectedDate,
                  selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    controller.onDateSelected(selectedDay);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Permanent OFF'),
                  subtitle: const Text('Turn off all meals indefinitely'),
                  value: controller.isPermanentOff,
                  onChanged: (val) => controller.togglePermanentOff(val),
                  activeThumbColor: Colors.red,
                ),
                SwitchListTile(
                  title: const Text('Morning Meal'),
                  subtitle: controller.isLockedMorning ? const Text('Locked', style: TextStyle(color: Colors.red)) : null,
                  value: controller.isMorningOn,
                  onChanged: controller.isLockedMorning 
                      ? null 
                      : (val) => controller.toggleMorning(val),
                ),
                SwitchListTile(
                  title: const Text('Evening Meal'),
                  subtitle: controller.isLockedEvening ? const Text('Locked', style: TextStyle(color: Colors.red)) : null,
                  value: controller.isEveningOn,
                  onChanged: controller.isLockedEvening 
                      ? null 
                      : (val) => controller.toggleEvening(val),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
