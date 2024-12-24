import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PomodoroState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _focusTime = 25 * 60;
  int _breakTime = 5 * 60;
  bool _isFocusTime = true;
  bool _isRunning = false;
  int _completedPomodoros = 0;
  bool _isLoading = false;
  String? _error;

  int get focusTime => _focusTime;
  int get breakTime => _breakTime;
  bool get isFocusTime => _isFocusTime;
  bool get isRunning => _isRunning;
  int get completedPomodoros => _completedPomodoros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPomodoroStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pomodoro_stats')
          .doc('daily')
          .get();

      if (doc.exists) {
        _completedPomodoros = doc.data()?['completed_pomodoros'] ?? 0;
      }

    } catch (e) {
      _error = 'Failed to load pomodoro stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> incrementCompletedPomodoros() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _completedPomodoros++;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pomodoro_stats')
          .doc('daily')
          .set({
        'completed_pomodoros': _completedPomodoros,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      _error = 'Failed to update pomodoro stats: $e';
      _completedPomodoros--; // Rollback optimistic update
      notifyListeners();
    }
  }

  void updateTimer(int newFocusMinutes, int newBreakMinutes) {
    _focusTime = newFocusMinutes * 60;
    _breakTime = newBreakMinutes * 60;
    notifyListeners();
  }

  void toggleTimer() {
    _isRunning = !_isRunning;
    notifyListeners();
  }

  void switchPhase() {
    _isFocusTime = !_isFocusTime;
    if (!_isFocusTime) {
      incrementCompletedPomodoros();
    }
    notifyListeners();
  }

  void resetTimer() {
    _focusTime = 25 * 60;
    _breakTime = 5 * 60;
    _isFocusTime = true;
    _isRunning = false;
    notifyListeners();
  }
}