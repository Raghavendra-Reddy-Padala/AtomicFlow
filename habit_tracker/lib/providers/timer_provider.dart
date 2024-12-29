import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerState {
  final int currentDuration;
  final bool isRunning;
  final bool isWorkTime;
  final String? sessionId;

  TimerState({
    required this.currentDuration,
    required this.isRunning,
    required this.isWorkTime,
    this.sessionId,
  });

  TimerState copyWith({
    int? currentDuration,
    bool? isRunning,
    bool? isWorkTime,
    String? sessionId,
  }) {
    return TimerState(
      currentDuration: currentDuration ?? this.currentDuration,
      isRunning: isRunning ?? this.isRunning,
      isWorkTime: isWorkTime ?? this.isWorkTime,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class TimerStateNotifier extends StateNotifier<TimerState> {
  static const int workDuration = 25 * 60;
  static const int breakDuration = 5 * 60;
  Timer? _timer;

  TimerStateNotifier() : super(TimerState(
    currentDuration: workDuration,
    isRunning: false,
    isWorkTime: true,
    sessionId: null,
  ));

  void startTimer() {
    if (!state.isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.currentDuration > 0) {
          state = state.copyWith(
            currentDuration: state.currentDuration - 1,
            isRunning: true,
          );
        } else {
          pauseTimer();
          state = state.copyWith(
            isWorkTime: !state.isWorkTime,
            currentDuration: state.isWorkTime ? breakDuration : workDuration,
            isRunning: false,
          );
        }
      });
      state = state.copyWith(isRunning: true);
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      currentDuration: state.isWorkTime ? workDuration : breakDuration,
    );
  }

  void setSessionId(String? sessionId) {
    state = state.copyWith(sessionId: sessionId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerStateNotifier, TimerState>((ref) {
  return TimerStateNotifier();
});