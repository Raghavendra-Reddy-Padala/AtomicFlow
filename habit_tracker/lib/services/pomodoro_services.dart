import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pomodoro_model.dart';
import 'databaseservice.dart';

final pomodoroServiceProvider = Provider<PomodoroService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PomodoroService(firestoreService);
});

class PomodoroService {
  final FirestoreService _firestoreService;
  static const String collection = 'pomodoro_sessions';

  PomodoroService(this._firestoreService);

  Future<String> startSession({
    required int duration,
    required bool isWorkSession,
  }) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Generate a unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final session = PomodoroModel(
      id: id,
      userId: userId,
      startTime: DateTime.now(),
      duration: duration,
      isWorkSession: isWorkSession,
      isCompleted: false,
    );

    // Use setData instead of direct Firestore access
    await _firestoreService.setData(
      path: '$collection/$id',
      data: session.toMap(),
    );

    return id;
  }

  Future<void> completeSession(String sessionId) async {
    await _firestoreService.updateData(
      path: '$collection/$sessionId',
      data: {
        'endTime': DateTime.now().toIso8601String(),
        'isCompleted': true,
      },
    );
  }

  Stream<List<PomodoroModel>> getUserSessions() {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _firestoreService.collectionStream(
      path: collection,
      builder: (data, id) => PomodoroModel.fromMap(data, id),
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _firestoreService.deleteData(path: '$collection/$sessionId');
  }

  Stream<PomodoroStats> getUserStats() {
    return getUserSessions().map((sessions) {
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final workSessions = completedSessions.where((s) => s.isWorkSession).length;
      final totalMinutes = completedSessions.fold<int>(
        0,
        (sum, session) => sum + session.duration ~/ 60,
      );

      return PomodoroStats(
        totalSessions: completedSessions.length,
        workSessions: workSessions,
        breakSessions: completedSessions.length - workSessions,
        totalMinutes: totalMinutes,
      );
    });
  }
}

class PomodoroStats {
  final int totalSessions;
  final int workSessions;
  final int breakSessions;
  final int totalMinutes;

  PomodoroStats({
    required this.totalSessions,
    required this.workSessions,
    required this.breakSessions,
    required this.totalMinutes,
  });
}