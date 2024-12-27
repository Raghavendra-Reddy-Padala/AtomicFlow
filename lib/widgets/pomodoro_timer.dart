import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({Key? key}) : super(key: key);

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with SingleTickerProviderStateMixin {
  static const int workDuration = 25 * 60;
  static const int breakDuration = 5 * 60;
  
  late Timer _timer;
  int _currentDuration = workDuration;
  bool _isRunning = false;
  bool _isWorkTime = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getTimeColor() {
    return _isWorkTime 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
  }

  void _startTimer() {
    _animationController.repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentDuration > 0) {
          _currentDuration--;
        } else {
          _timer.cancel();
          _animationController.stop();
          _isRunning = false;
          _isWorkTime = !_isWorkTime;
          _currentDuration = _isWorkTime ? workDuration : breakDuration;
          _showCompletionDialog();
        }
      });
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer.cancel();
    _animationController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer.cancel();
    _animationController.stop();
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
    final color = _getTimeColor();
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          _isWorkTime ? 'Break Time!' : 'Back to Work!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        content: Text(
          _isWorkTime
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
              _startTimer();
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

  @override
  Widget build(BuildContext context) {
    final color = _getTimeColor();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
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
                    _isWorkTime ? 'Work Time' : 'Break Time',
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
                      _formatTime(_currentDuration),
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
                  icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: color,
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 32),
                _TimerButton(
                  icon: Icons.refresh_rounded,
                  color: color,
                  onPressed: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
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