import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/services/pomodoro_services.dart';

// Create a provider to hold the timer state
final pomodoroStateProvider = StateNotifierProvider<PomodoroStateNotifier, PomodoroState>((ref) {
  return PomodoroStateNotifier();
});




// State class to hold all timer-related data
class PomodoroState {
  final int currentDuration;
  final bool isRunning;
  final bool isWorkTime;
  final String? sessionId;
  final Timer? timer;

  PomodoroState({
    required this.currentDuration,
    required this.isRunning,
    required this.isWorkTime,
    this.sessionId,
    this.timer,
  });

  PomodoroState copyWith({
    int? currentDuration,
    bool? isRunning,
    bool? isWorkTime,
    String? sessionId,
    Timer? timer,
  }) {
    return PomodoroState(
      currentDuration: currentDuration ?? this.currentDuration,
      isRunning: isRunning ?? this.isRunning,
      isWorkTime: isWorkTime ?? this.isWorkTime,
      sessionId: sessionId ?? this.sessionId,
      timer: timer ?? this.timer,
    );
  }
}


// StateNotifier to manage the timer state
class PomodoroStateNotifier extends StateNotifier<PomodoroState> {

  
  static const int workDuration = 25 * 60;
  static const int breakDuration = 5 * 60;

  PomodoroStateNotifier()
      : super(PomodoroState(
          currentDuration: workDuration,
          isRunning: false,
          isWorkTime: true,
        ));
void _completeCurrentSession() {
  if (state.sessionId != null) {
    // You'll need to pass the pomodoroService to this class or use a callback
    // This is just a placeholder for the concept
    // In practice, you might want to handle this in the widget
    _notifySessionComplete(state.sessionId!);
  }
}

void _notifySessionComplete(String sessionId) {
  // Implement the logic to notify about session completion
  // For example, you might want to update the database or trigger some UI changes
  print('Session $sessionId completed');
}
void startTimer() {
  if (!state.isRunning) {
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.currentDuration > 0) {
        state = state.copyWith(
          currentDuration: state.currentDuration - 1,
        );
      } else {
        pauseTimer();
        // Session is complete, so we should complete it in Firebase
        if (state.sessionId != null) {
          // We need to use a callback here since we can't make this method async
          _completeCurrentSession();
        }
        state = state.copyWith(
          isWorkTime: !state.isWorkTime,
          currentDuration: state.isWorkTime ? breakDuration : workDuration,
          isRunning: false,
          sessionId: null, // Clear the session ID after completion
        );
      }
    });
    state = state.copyWith(isRunning: true, timer: timer);
  }
}

  void pauseTimer() {
    state.timer?.cancel();
    state = state.copyWith(isRunning: false, timer: null);
  }

  void resetTimer() {
    state.timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      currentDuration: state.isWorkTime ? workDuration : breakDuration,
      timer: null,
    );
  }

  void setSessionId(String? id) {
    state = state.copyWith(sessionId: id);
  }

  @override
  void dispose() {
    state.timer?.cancel();
    super.dispose();
  }
}

class PomodoroTimer extends ConsumerStatefulWidget {
  const PomodoroTimer({Key? key}) : super(key: key);

  @override
  ConsumerState<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends ConsumerState<PomodoroTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  void Function(String)? notifySessionComplete;

  @override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  
  // Set up the callback
  notifySessionComplete = (String sessionId) {
    _completeSession();
  };
}


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTimeColor() {
    final state = ref.watch(pomodoroStateProvider);
    return state.isWorkTime
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
  }

  Future<void> _startNewSession() async {
    final state = ref.read(pomodoroStateProvider);
    final pomodoroService = ref.read(pomodoroServiceProvider);
    final sessionId = await pomodoroService.startSession(
      duration: state.isWorkTime ? 25 * 60 : 5 * 60,
      isWorkSession: state.isWorkTime,
    );
    ref.read(pomodoroStateProvider.notifier).setSessionId(sessionId);
  }

  Future<void> _completeSession() async {
    final state = ref.read(pomodoroStateProvider);
    if (state.sessionId != null) {
      final pomodoroService = ref.read(pomodoroServiceProvider);
      await pomodoroService.completeSession(state.sessionId!);
      ref.read(pomodoroStateProvider.notifier).setSessionId(null);
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showCompletionDialog() async {
    final color = _getTimeColor();
    final state = ref.read(pomodoroStateProvider);
    
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          state.isWorkTime ? 'Break Time!' : 'Back to Work!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        content: Text(
          state.isWorkTime
              ? 'Great job! Take a 5-minute break.'
              : 'Break is over. Ready to focus again?',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStart();
            },
            style: TextButton.styleFrom(
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Start',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStart() async {
  if (!ref.read(pomodoroStateProvider).isRunning) {
    // Only create a new session if we're starting fresh
    if (ref.read(pomodoroStateProvider).currentDuration == 
        (ref.read(pomodoroStateProvider).isWorkTime ? 25 * 60 : 5 * 60)) {
      await _startNewSession();
    }
    ref.read(pomodoroStateProvider.notifier).startTimer();
    _animationController.repeat();
  }
}

 void _handlePause() {
  ref.read(pomodoroStateProvider.notifier).pauseTimer();
  _animationController.stop();
  // Remove the _completeSession call from here
}

 void _handleReset() {
  final state = ref.read(pomodoroStateProvider);
  if (state.sessionId != null) {
    // Only delete the session if we reset before completion
    ref.read(pomodoroServiceProvider).deleteSession(state.sessionId!);
    ref.read(pomodoroStateProvider.notifier).setSessionId(null);
  }
  ref.read(pomodoroStateProvider.notifier).resetTimer();
  _animationController.stop();
}

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroStateProvider);
    final color = _getTimeColor();
    final colorScheme = Theme.of(context).colorScheme;

    // Update animation controller based on timer state
    if (state.isRunning && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!state.isRunning && _animationController.isAnimating) {
      _animationController.stop();
    }

    return Column(
      children: [
        Card(
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withOpacity(0.9),
                  colorScheme.surface.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pomodoro Timer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        state.isWorkTime ? 'Work Time' : 'Break Time',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _animationController,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.4),
                              color.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(state.currentDuration),
                          style: GoogleFonts.poppins(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimerButton(
                      icon: state.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: color,
                      onPressed: state.isRunning ? _handlePause : _handleStart,
                    ),
                    const SizedBox(width: 32),
                    _TimerButton(
                      icon: Icons.refresh_rounded,
                      color: color,
                      onPressed: _handleReset,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder(
          stream: ref.watch(pomodoroServiceProvider).getUserStats(),
          builder: (context, AsyncSnapshot<PomodoroStats> snapshot) {
            if (!snapshot.hasData) {
              return const Text("No data yet");
            }

            final stats = snapshot.data!;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Focus Stats',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Sessions',
                        stats.totalSessions.toString(),
                        Icons.timer_outlined,
                        color,
                      ),
                      _buildStatItem(
                        'Work Sessions',
                        stats.workSessions.toString(),
                        Icons.work_outline,
                        color,
                      ),
                      _buildStatItem(
                        'Total Minutes',
                        stats.totalMinutes.toString(),
                        Icons.access_time,
                        color,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _TimerButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      color: color.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            size: 36,
            color: color,
          ),
        ),
      ),
    );
  }
}