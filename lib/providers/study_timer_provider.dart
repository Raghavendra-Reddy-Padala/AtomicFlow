// Add this at the top of your file or in a separate study_timer_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studyTimerProvider = StateNotifierProvider<StudyTimerNotifier, Map<String, StudyTimerState>>((ref) {
  return StudyTimerNotifier();
});

class StudyTimerState {
  final int elapsedSeconds;
  final bool isRunning;
  final String? sessionId;

  StudyTimerState({
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.sessionId,
  });

  StudyTimerState copyWith({
    int? elapsedSeconds,
    bool? isRunning,
    String? sessionId,
  }) {
    return StudyTimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class StudyTimerNotifier extends StateNotifier<Map<String, StudyTimerState>> {
  Map<String, Timer> _timers = {};

  StudyTimerNotifier() : super({});

  void startTimer(String userId) {
    if (!state[userId]!.isRunning ?? true) {
      _timers[userId]?.cancel();
      _timers[userId] = Timer.periodic(const Duration(seconds: 1), (_) {
        state = {
          ...state,
          userId: StudyTimerState(
            elapsedSeconds: (state[userId]?.elapsedSeconds ?? 0) + 1,
            isRunning: true,
            sessionId: state[userId]?.sessionId,
          ),
        };
      });
    }
  }

    void pauseTimer(String userId) {
    _timers[userId]?.cancel();
    state = {
      ...state,
      userId: StudyTimerState(
        elapsedSeconds: state[userId]?.elapsedSeconds ?? 0,
        isRunning: false,
        sessionId: state[userId]?.sessionId,
      ),
    };
  }

  void setSessionId(String userId, String sessionId) {
    state = {
      ...state,
      userId: StudyTimerState(
        elapsedSeconds: state[userId]?.elapsedSeconds ?? 0,
        isRunning: state[userId]?.isRunning ?? false,
        sessionId: sessionId,
      ),
    };
  }
   void resetTimer(String userId) {
    _timers[userId]?.cancel();
    state = {
      ...state,
      userId: StudyTimerState(),
    };
  }

 @override 
  void dispose() {
    _timers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }
}
