import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habit_tracker/models/pomodoro_state.dart';
import 'package:provider/provider.dart';

class PomodoroSection extends StatefulWidget {
  const PomodoroSection({Key? key}) : super(key: key);

  @override
  _PomodoroSectionState createState() => _PomodoroSectionState();
}

class _PomodoroSectionState extends State<PomodoroSection> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    context.read<PomodoroState>().loadPomodoroStats();
  }

  void _startTimer() {
    final pomodoroState = context.read<PomodoroState>();
    pomodoroState.toggleTimer();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = context.read<PomodoroState>();
      if (!state.isRunning) {
        timer.cancel();
        return;
      }

      if (state.isFocusTime) {
        if (state.focusTime > 0) {
          state.updateTimer(
            state.focusTime ~/ 60,
            state.breakTime ~/ 60,
          );
        } else {
          state.switchPhase();
        }
      } else {
        if (state.breakTime > 0) {
          state.updateTimer(
            state.focusTime ~/ 60,
            state.breakTime ~/ 60,
          );
        } else {
          state.switchPhase();
          timer.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Pomodoro Timer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isLoading)
                  const CircularProgressIndicator()
                else ...[
                  // Timer Display
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: state.isFocusTime
                            ? 1 - (state.focusTime / (25 * 60))
                            : 1 - (state.breakTime / (5 * 60)),
                          strokeWidth: 15,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            state.isFocusTime ? Colors.red : Colors.green,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(
                                  state.isFocusTime
                                    ? state.focusTime
                                    : state.breakTime,
                                ),
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completed: ${state.completedPomodoros}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: state.isRunning ? null : _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: state.isRunning
                          ? () => context.read<PomodoroState>().toggleTimer()
                          : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<PomodoroState>().resetTimer(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}