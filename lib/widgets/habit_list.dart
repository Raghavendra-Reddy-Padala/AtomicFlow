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
    Colors.blue,   // Morning
    Colors.green,  // Afternoon
    Colors.purple, // Evening
    Colors.orange, // Night
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section matching notes UI
              Row(
                children: [
                  Text(
                    'Habits',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showHabitDialog(),
                    tooltip: 'Add New Habit',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Habits list section
              Expanded(
                child: StreamBuilder<List<HabitModel>>(
                  stream: ref.read(habitServiceProvider).getUserHabits(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final habits = snapshot.data ?? [];

                    if (habits.isEmpty) {
                      return Center(
                        child: Text(
                          'No habits yet. Create one!',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final habitColor = Color(
                          int.parse('0xFF${habit.color.substring(1)}'),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: habitColor.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: habitColor.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: habitColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: habitColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (habit.description?.isNotEmpty ?? false)
                                            Text(
                                              habit.description!,
                                              style: GoogleFonts.poppins(
                                                
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: habitColor,
                                        size: 20,
                                      ),
                                      onPressed: () => _showHabitDialog(habit),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteHabit(habit.id),
                                    ),
                                  ],
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: habitColor.withOpacity(0.05),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Today's completion toggle
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: habitColor.withOpacity(0.2),
                                            ),
                                          ),
                                          child: CheckboxListTile(
                                            title: Text(
                                              "Today's Progress",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            value: habit.completionStatus[
                                              DateTime.now().toIso8601String().split('T')[0]
                                            ] ?? false,
                                            onChanged: (value) {
                                              ref.read(habitServiceProvider).toggleHabitCompletion(
                                                habit.id,
                                                DateTime.now(),
                                              );
                                            },
                                            activeColor: habitColor,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Progress History',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 240,
                                          child: HabitHeatmap(
                                            habit: habit,
                                            color: habitColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to delete a habit with confirmation
  Future<void> _deleteHabit(String habitId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this habit?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      await ref.read(habitServiceProvider).deleteHabit(habitId);
    }
  }

}