import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class Habit {
  String id;
  String name;
  List<DateTime> completedDays;
  String userId;
  DateTime createdAt;
  StateMachineController? controller;
  SMIInput<double>? progressInput;

  Habit({
    required this.id,
    required this.name,
    required this.userId,
    List<DateTime>? completedDays,
    DateTime? createdAt,
  })  : completedDays = completedDays ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      completedDays: (data['completedDays'] as List?)
              ?.map((timestamp) => (timestamp as Timestamp).toDate())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'completedDays':
          completedDays.map((date) => Timestamp.fromDate(date)).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get completionPercentage {
    if (completedDays.isEmpty) return 0;
    final daysFromCreation = DateTime.now().difference(createdAt).inDays;
    if (daysFromCreation == 0) return 0;
    return completedDays.length / daysFromCreation;
  }
}

class HabitDatabase extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> addHabit(String habitName) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'User must be logged in';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final newHabit = Habit(
        id: DateTime.now().toString(),
        name: habitName,
        userId: user.uid,
      );

      _habits.add(newHabit);
      notifyListeners();

      final docRef =
          await _firestore.collection('habits').add(newHabit.toFirestore());
      newHabit.id = docRef.id;
      _habits[_habits.length - 1] = newHabit;
    } catch (e) {
      _error = 'Failed to add habit: $e';
      _habits.removeLast();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> readHabits() async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'User must be logged in';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _habits =
          querySnapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load habits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHabitCompletion(String habitId, bool isCompleted) async {
    try {
      final habitIndex = _habits.indexWhere((h) => h.id == habitId);
      if (habitIndex == -1) return;

      final habit = _habits[habitIndex];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (isCompleted) {
        if (!habit.completedDays.contains(todayDate)) {
          habit.completedDays.add(todayDate);
        }
      } else {
        habit.completedDays.removeWhere(
          (date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day,
        );
      }
      notifyListeners();

      await _firestore.runTransaction((transaction) async {
        final habitRef = _firestore.collection('habits').doc(habitId);
        final snapshot = await transaction.get(habitRef);

        if (!snapshot.exists) throw Exception('Habit not found');

        transaction.update(habitRef, habit.toFirestore());
      });
    } catch (e) {
      _error = 'Failed to update habit: $e';
      await readHabits();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    Habit? deletedHabit;
    int? habitIndex;

    try {
      habitIndex = _habits.indexWhere((h) => h.id == habitId);
      if (habitIndex == -1) return;

      deletedHabit = _habits.removeAt(habitIndex);
      notifyListeners();

      await _firestore.collection('habits').doc(habitId).delete();
    } catch (e) {
      _error = 'Failed to delete habit: $e';
      if (deletedHabit != null && habitIndex != null) {
        _habits.insert(habitIndex, deletedHabit);
        notifyListeners();
      }
    }
  }

  // Get first launch date (for heatmap) with error handling
  Future<DateTime> getFirstLaunchDate() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data()?['firstLaunchDate'] != null) {
        return (userDoc.data()?['firstLaunchDate'] as Timestamp).toDate();
      }

      // If no first launch date, create one
      final now = DateTime.now();
      await _firestore.collection('users').doc(user.uid).set({
        'firstLaunchDate': Timestamp.fromDate(now)
      }, SetOptions(merge: true));

      return now;
    } catch (e) {
      _error = 'Failed to get first launch date: $e';
      return DateTime.now();
    }
  }
}
