import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/services/habit_service.dart';
import '../models/habit_model.dart';
import '../models/user_stats_model.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final habitService = ref.watch(habitServiceProvider);
  return StatsService(habitService);
});

class StatsService {
  final HabitService _habitService;

  StatsService(this._habitService);

  Stream<UserStatsModel> getUserStats() {
    return _habitService.getUserHabits().map((habits) {
      return UserStatsModel(
        currentStreak: _calculateCurrentStreak(habits),
        completionRate: _calculateCompletionRate(habits),
        totalHabits: habits.length,
      );
    });
  }

  int _calculateCurrentStreak(List<HabitModel> habits) {
    if (habits.isEmpty) return 0;

    // Get today's date without time
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    
    // Create a set of dates where ANY habit was completed
    final completedDates = <String>{};
    for (var habit in habits) {
      habit.completionStatus.forEach((date, completed) {
        if (completed) completedDates.add(date);
      });
    }

    // Calculate streak
    int streak = 0;
    DateTime checkDate = dateOnly;
    
    // Check today first
    String checkDateStr = checkDate.toIso8601String().split('T')[0];
    bool todayCompleted = completedDates.contains(checkDateStr);
    
    // If today is not yet completed, start checking from yesterday
    if (!todayCompleted) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Count consecutive days
    while (true) {
      checkDateStr = checkDate.toIso8601String().split('T')[0];
      if (!completedDates.contains(checkDateStr)) {
        break;
      }
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  double _calculateCompletionRate(List<HabitModel> habits) {
    if (habits.isEmpty) return 0.0;

    // Get the last 7 days
    final today = DateTime.now();
    final dates = List.generate(7, (index) {
      final date = today.subtract(Duration(days: index));
      return date.toIso8601String().split('T')[0];
    });

    int totalPossibleCompletions = habits.length * 7; // Total habits × 7 days
    int totalCompletions = 0;

    // Count completions for each habit in the last 7 days
    for (var habit in habits) {
      for (var date in dates) {
        if (habit.completionStatus[date] == true) {
          totalCompletions++;
        }
      }
    }

    // Calculate completion rate as percentage
    return totalPossibleCompletions > 0
        ? (totalCompletions / totalPossibleCompletions) * 100
        : 0.0;
  }
}