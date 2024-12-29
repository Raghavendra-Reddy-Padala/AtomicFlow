import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../models/habit_model.dart';

class HabitHeatmap extends StatelessWidget {
  final HabitModel habit;
  final Color color;

  const HabitHeatmap({
    Key? key,
    required this.habit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert completion status to heatmap dataset
    final datasets = habit.completionStatus.map(
      (date, completed) => MapEntry(
        DateTime.parse(date),
        completed ? 1 : 0,
      ),
    );

    return HeatMapCalendar(
      datasets: datasets,
      colorMode: ColorMode.color,
      defaultColor: Colors.grey[300],
      textColor: Theme.of(context).textTheme.bodyMedium?.color,
      showColorTip: false,
      colorsets: {
        1: color.withOpacity(0.7),
      },
      onClick: (value) {
        if (value != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                habit.completionStatus[value.toIso8601String().split('T')[0]] ?? false
                    ? 'Completed on ${value.day}-${value.month}-${value.year}'
                    : 'Not completed on ${value.day}-${value.month}-${value.year}',
              ),
            ),
          );
        }
      },
    );
  }
}