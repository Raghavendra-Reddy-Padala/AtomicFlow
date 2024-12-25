import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({Key? key}) : super(key: key);

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int workDuration = 25 * 60; // 25 minutes in seconds
  static const int breakDuration = 5 * 60; // 5 minutes in seconds
  
  late Timer _timer;
  int _currentDuration = workDuration;
  bool _isRunning = false;
  bool _isWorkTime = true;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentDuration > 0) {
          _currentDuration--;
        } else {
          _timer.cancel();
          _isRunning = false;
          // Switch between work and break
          _isWorkTime = !_isWorkTime;
          _currentDuration = _isWorkTime ? workDuration : breakDuration;
          // Show notification
          _showCompletionDialog();
        }
      });
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
      _currentDuration = _isWorkTime ? workDuration : breakDuration;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showCompletionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isWorkTime ? 'Break Time!' : 'Back to Work!'),
        content: Text(
          _isWorkTime
              ? 'Great job! Take a 5-minute break.'
              : 'Break is over. Ready to focus again?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pomodoro Timer',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isWorkTime ? 'Work Time' : 'Break Time',
              style: GoogleFonts.poppins(
                color: _isWorkTime ? Colors.purple : Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _formatTime(_currentDuration),
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetTimer,
                  iconSize: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}