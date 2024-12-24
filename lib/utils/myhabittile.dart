import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_tracker/backend/Habit_database.dart';

// Habit Tile Widget
class Myhabittile extends StatelessWidget {
  final bool isCompleted;
  final String text;
  final void Function(bool?)? x;
  final void Function(BuildContext)? editHabit;
  final void Function(BuildContext)? deleteHabit;
    final void Function()? ontap;  // Add this line


  const Myhabittile({
    super.key,
    required this.isCompleted,
    required this.text,
    required this.x,
    required this.editHabit,
    required this.deleteHabit,
      this.ontap,  // Add this line

  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
     onTap: ontap,  // Add this line

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        child: Slidable(
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              // Edit option
              SlidableAction(
                onPressed: editHabit,
                backgroundColor: Colors.grey.shade800,
                icon: Icons.settings,
              ),
              // Delete option
              SlidableAction(
                onPressed: deleteHabit,
                backgroundColor: Colors.red,
                icon: Icons.delete,
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              if (x != null) {
                x!(!isCompleted);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted 
                  ? Colors.green 
                  : Theme.of(context).colorScheme.secondary ?? Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(
                  text,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.black.withOpacity(0.7),
                  ),
                ),
                leading: Checkbox(
                  activeColor: Colors.green,
                  value: isCompleted,
                  onChanged: x,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Utility Functions
// Check if habit is completed today
bool isHabitCompltedToday(List<DateTime> compltedDays) {
  final today = DateTime.now();
  return compltedDays.any(
    (date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day,
  );
}

// Prepare heatmap dataset
Map<DateTime, int> prepHeatMapDataset(List<Habit> habits) {
  Map<DateTime, int> dataset = {};
  
  for (var habit in habits) {
    for (var date in habit.completedDays) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // If the date already exists in the dataset, increment its count
      dataset[normalizedDate] = (dataset[normalizedDate] ?? 0) + 1;
    }
  }
  
  return dataset;
}