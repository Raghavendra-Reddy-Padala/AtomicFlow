import 'package:flutter/material.dart';
import 'package:habit_tracker/backend/Habit_database.dart';
import 'package:habit_tracker/components/habit_ball.dart';
import 'package:habit_tracker/components/myheatmap.dart';

class HabitTrackerSection extends StatefulWidget {
  const HabitTrackerSection({Key? key}) : super(key: key);

  @override
  _HabitTrackerSectionState createState() => _HabitTrackerSectionState();
}

class _HabitTrackerSectionState extends State<HabitTrackerSection> {
  final HabitDatabase _habitDatabase = HabitDatabase();
  
  @override
  void initState() {
    super.initState();
    _habitDatabase.readHabits();
  }

  bool _isHabitCompletedToday(List<DateTime> completedDays) {
    final today = DateTime.now();
    return completedDays.any((date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day
    );
  }
  void _showCreateHabitDialog(BuildContext context) {
  final TextEditingController habitNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create a New Habit'),
        content: TextField(
          controller: habitNameController,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            hintText: 'Enter the name of your habit',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final habitName = habitNameController.text.trim();
              if (habitName.isNotEmpty) {
                // Use the _habitDatabase instance from the current state
                await _habitDatabase.addHabit(habitName);
                Navigator.of(context).pop(); // Close the dialog
              }
            },
            child: const Text('Add Habit'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _habitDatabase,
      builder: (context, child) {
        if (_habitDatabase.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_habitDatabase.error != null) {
          return Center(
            child: Text(
              _habitDatabase.error!,
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              centerTitle: true,
              title: Text(
                'Habit Tracker',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateHabitDialog(context),
                ),
              ],
            ),
            // Heatmap
            if (_habitDatabase.habits.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FutureBuilder<DateTime>(
                  future: _habitDatabase.getFirstLaunchDate(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Myheatmap(
                        datasets: _prepHeatMapDataset(_habitDatabase.habits),
                        startDate: snapshot.data!,
                      ),
                    );
                  },
                ),
              ),
              // Habit Balls
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = _habitDatabase.habits[index];
                      return HabitBall(
                        habitId: habit.id,
                        name: habit.name,
                        completedDays: habit.completedDays,
                        createdAt: habit.createdAt,
                        isCompleted: _isHabitCompletedToday(habit.completedDays),
                        onToggle: (isCompleted) {
                          _habitDatabase.updateHabitCompletion(
                            habit.id,
                            isCompleted,
                          );
                        },
                      );
                    },
                    childCount: _habitDatabase.habits.length,
                  ),
                ),
              ),
            ] else ...[
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No habits yet. Add one to get started!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Map<DateTime, int> _prepHeatMapDataset(List<Habit> habits) {
    final Map<DateTime, int> dataset = {};
    for (final habit in habits) {
      for (final date in habit.completedDays) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        dataset[normalizedDate] = (dataset[normalizedDate] ?? 0) + 1;
      }
    }
    return dataset;
  }
  
}

