import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_session_model.dart';
import '../models/user_model.dart';
import 'databaseservice.dart';

final studyRoomServiceProvider = Provider<StudyRoomService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return StudyRoomService(firestoreService);
});

class StudyRoomService {
  final FirestoreService _firestoreService;
  static const String collection = 'study_sessions';

  StudyRoomService(this._firestoreService);

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
  // Add this method that was missing
  Future<StudySessionModel?> getCurrentSession(String userId) async {
    try {
      final sessionData = await _firestoreService.getDocument(
        collection,
        conditions: {
          'userId': userId,
          'isActive': true,
          'date': _firestoreService.getTodayDate(),
        },
      );

      if (sessionData == null) return null;
      
      return StudySessionModel.fromMap(sessionData, sessionData['id']);
    } catch (e) {
      print('Error getting current session: $e');
      return null;
    }
  }

   Future<String> startSession(UserModel user) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // Check for existing active session from today
    final existingSession = await getCurrentSession(userId);
    if (existingSession != null) {
      // Resume existing session instead of creating new
      return existingSession.id;
    }
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final session = StudySessionModel(
      id: id,
      userId: userId,
      username: user.username,
      userProfileUrl: user.profileImageUrl,
      startTime: DateTime.now(),
      totalMinutes: 0,
      isActive: true,
      date: _getTodayDate(),
      timeSegments: [TimeSegment(startTime: DateTime.now())],
    );

    await _firestoreService.setData(
      path: '$collection/$id',
      data: session.toMap(),
    );

    return id;
  }

  //   // Schedule session end at midnight
  //   final now = DateTime.now();
  //   final midnight = DateTime(now.year, now.month, now.day + 1);
  //   final duration = midnight.difference(now);
    
  //   Future.delayed(duration, () async {
  //     try {
  //       await endSession(id);
  //     } catch (e) {
  //       print('Error ending session at midnight: $e');
  //     }
  //   });

  //   return id;
  // }

  Future<String> resumeSession(String sessionId) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final session = await _firestoreService.getData(path: '$collection/$sessionId');
    
    if (session['userId'] != userId) {
      throw Exception('Unauthorized to resume this session');
    }

    final timeSegments = (session['timeSegments'] as List<dynamic>).map(
      (segment) => TimeSegment.fromMap(segment as Map<String, dynamic>)
    ).toList();

    timeSegments.add(TimeSegment(startTime: DateTime.now()));

    await _firestoreService.updateData(
      path: '$collection/$sessionId',
      data: {
        'isActive': true,
        'timeSegments': timeSegments.map((segment) => segment.toMap()).toList(),
      },
    );

    return sessionId;
  }

 Future<void> pauseSession(String sessionId) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final session = await _firestoreService.getData(path: '$collection/$sessionId');
    
    if (session['userId'] != userId) {
      throw Exception('Unauthorized to pause this session');
    }

    final timeSegments = (session['timeSegments'] as List<dynamic>)
        .map((segment) => TimeSegment.fromMap(segment as Map<String, dynamic>))
        .toList();

    // Update last segment's end time
    if (timeSegments.isNotEmpty && timeSegments.last.endTime == null) {
      timeSegments.last = TimeSegment(
        startTime: timeSegments.last.startTime,
        endTime: DateTime.now(),
      );
    }

    final totalMinutes = _calculateTotalMinutes(timeSegments);

    await _firestoreService.updateData(
      path: '$collection/$sessionId',
      data: {
        'isActive': false,
        'timeSegments': timeSegments.map((segment) => segment.toMap()).toList(),
        'totalMinutes': totalMinutes,
      },
    );
  }

  int _calculateTotalMinutes(List<TimeSegment> segments) {
    return segments.fold<int>(0, (total, segment) {
      if (segment.endTime == null) return total;
      return total + segment.endTime!.difference(segment.startTime).inMinutes;
    });
  }

   Future<void> updateSessionTime(String sessionId, int totalMinutes) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final session = await _firestoreService.getData(path: '$collection/$sessionId');
    
    if (session['userId'] != userId) {
      throw Exception('Unauthorized to update this session');
    }

    await _firestoreService.updateData(
      path: '$collection/$sessionId',
      data: {
        'totalMinutes': totalMinutes,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
    );
  }
  
  Future<void> endSession(String sessionId) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final session = await _firestoreService.getData(path: '$collection/$sessionId');
    
    if (session['userId'] != userId) {
      throw Exception('Unauthorized to end this session');
    }

    await _firestoreService.updateData(
      path: '$collection/$sessionId',
      data: {
        'endTime': DateTime.now().toIso8601String(),
        'isActive': false,
      },
    );
  }

  Stream<StudySessionModel?> getCurrentUserSession() {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _firestoreService.collectionStream(
      path: collection,
      builder: (data, id) => StudySessionModel.fromMap(data, id),
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: _getTodayDate())
          .where('isActive', isEqualTo: true)
          .limit(1),
    ).map((sessions) => sessions.isEmpty ? null : sessions.first);
  }

   Stream<List<StudySessionModel>> getDailyRankings() {
    return _firestoreService.collectionStream(
      path: collection,
      builder: (data, id) => StudySessionModel.fromMap(data, id),
      queryBuilder: (query) => query
          .where('date', isEqualTo: _getTodayDate())
          .orderBy('totalMinutes', descending: true)
          .limit(10),
    );
  }
}