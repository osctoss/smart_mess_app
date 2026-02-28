import 'package:flutter/material.dart' hide MenuController;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'menu_controller.dart'; // Renamed to avoid alias conflict
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/custom_text_field.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Menu Management')),
        body: Consumer<MenuController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.selectedDate == DateTime.now()) { // Initial loading
              return const Center(child: CircularProgressIndicator());
            }
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 7)),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: controller.selectedDate,
                    currentDay: DateTime.now(),
                    selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      controller.onDateSelected(selectedDay);
                    },
                    calendarFormat: CalendarFormat.week,
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: controller.morningController,
                          label: 'Morning Menu',
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: controller.eveningController,
                          label: 'Evening Menu',
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Save Menu',
                          onPressed: () => controller.saveMenu(context),
                          isLoading: controller.isLoading,
                        ),
                      ],
                    ),
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
