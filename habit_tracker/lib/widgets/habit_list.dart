import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import 'habit_heatmap.dart';

class HabitList extends ConsumerStatefulWidget {
  const HabitList({Key? key}) : super(key: key);

  @override
  ConsumerState<HabitList> createState() => _HabitListState();
}

class _HabitListState extends ConsumerState<HabitList> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#4CAF50';

  final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showHabitDialog([HabitModel? habit]) async {
    if (habit != null) {
      _titleController.text = habit.title;
      _descriptionController.text = habit.description ?? '';
      _selectedColor = habit.color;
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _selectedColor = '#4CAF50';
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          habit == null ? 'Add New Habit' : 'Edit Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _availableColors.map((color) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = '#${color.value.toRadixString(16).substring(2)}';
                      });
                      Navigator.pop(context);
                      _showHabitDialog(habit);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: color,
                      child: _selectedColor == '#${color.value.toRadixString(16).substring(2)}'
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _titleController.clear();
              _descriptionController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) return;

              if (habit == null) {
                await ref.read(habitServiceProvider).createHabit(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      color: _selectedColor,
                    );
              } else {
                await ref.read(habitServiceProvider).updateHabit(
                      habitId: habit.id,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      color: _selectedColor,
                    );
              }

              if (mounted) {
                Navigator.pop(context);
                _titleController.clear();
                _descriptionController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse('0xFF${_selectedColor.substring(1)}')),
            ),
            child: Text(habit == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HabitModel>>(
      stream: ref.read(habitServiceProvider).getUserHabits(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = snapshot.data ?? [];

        return Column(
          children: [
            // Add Habit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showHabitDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Habit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // Habits List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final habitColor = Color(
                  int.parse('0xFF${habit.color.substring(1)}'),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      habit.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      habit.description ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showHabitDialog(habit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Habit'),
                                content: const Text(
                                  'Are you sure you want to delete this habit?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref
                                  .read(habitServiceProvider)
                                  .deleteHabit(habit.id);
                            }
                          },
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Today's completion toggle
                            CheckboxListTile(
                              title: const Text("Today's Progress"),
                              value: habit.completionStatus[
                                  DateTime.now().toIso8601String().split('T')[0]] ??
                                  false,
                              onChanged: (value) {
                                ref
                                    .read(habitServiceProvider)
                                    .toggleHabitCompletion(
                                      habit.id,
                                      DateTime.now(),
                                    );
                              },
                              activeColor: habitColor,
                            ),
                            const SizedBox(height: 16),
                            // Habit's heatmap
                            HabitHeatmap(
                              habit: habit,
                              color: habitColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}