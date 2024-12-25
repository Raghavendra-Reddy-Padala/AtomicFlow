import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/services/databaseservice.dart';
import '../models/habit_model.dart';

final habitServiceProvider = Provider<HabitService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return HabitService(firestoreService);
});

class HabitService {
  final FirestoreService _firestoreService;
  
  HabitService(this._firestoreService);

  // Create a new habit
  Future<void> createHabit({
    required String title,
    String? description,
    String? color,
  }) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    await _firestoreService.setData(
      path: 'habits/${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'userId': userId,
        'title': title,
        'description': description,
        'completionStatus': {},
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'color': color ?? '#4CAF50',
      },
    );
  }

  // Update habit
  Future<void> updateHabit({
    required String habitId,
    String? title,
    String? description,
    String? color,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (color != null) updates['color'] = color;

    await _firestoreService.updateData(
      path: 'habits/$habitId',
      data: updates,
    );
  }

  // Toggle habit completion
  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final habitDoc = await _firestoreService.documentStream(
      path: 'habits/$habitId',
      builder: (data, id) => HabitModel.fromMap(data, id),
    ).first;

    if (habitDoc == null) throw Exception('Habit not found');

    final newStatus = Map<String, bool>.from(habitDoc.completionStatus);
    newStatus[dateStr] = !(newStatus[dateStr] ?? false);

    await _firestoreService.updateData(
      path: 'habits/$habitId',
      data: {
        'completionStatus': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Delete habit
  Future<void> deleteHabit(String habitId) async {
    await _firestoreService.deleteData(path: 'habits/$habitId');
  }

  // Get all habits stream
  Stream<List<HabitModel>> getUserHabits() {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _firestoreService.collectionStream(
      path: 'habits',
      builder: (data, id) => HabitModel.fromMap(data, id),
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    );
  }

  // Get single habit stream
  Stream<HabitModel?> getHabit(String habitId) {
    return _firestoreService.documentStream(
      path: 'habits/$habitId',
      builder: (data, id) => HabitModel.fromMap(data, id),
    );
  }
}