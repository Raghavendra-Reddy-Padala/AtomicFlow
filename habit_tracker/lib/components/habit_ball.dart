import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class HabitBall extends StatefulWidget {
  final String habitId;
  final String name;
  final List<DateTime> completedDays;
  final DateTime createdAt;
  final Function(bool) onToggle;
  final bool isCompleted;

  const HabitBall({
    super.key,
    required this.habitId,
    required this.name,
    required this.completedDays,
    required this.createdAt,
    required this.onToggle,
    required this.isCompleted,
  });

  @override
  State<HabitBall> createState() => _HabitBallState();
}

class _HabitBallState extends State<HabitBall> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  StateMachineController? _riveController;
  SMIInput<double>? _progressInput;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'habit_state_machine',
    );
    artboard.addController(controller!);
    _riveController = controller;
    _progressInput = controller.findInput('progress');
    _updateProgress();
  }

  void _updateProgress() {
    if (_progressInput != null) {
      final progress = widget.completedDays.length / 
        DateTime.now().difference(widget.createdAt).inDays;
      _progressInput!.value = progress.clamp(0.0, 1.0);
    }
  }

  double _getBallSize() {
    final count = widget.completedDays.length;
    if (count < 5) return 60;
    if (count < 10) return 80;
    if (count < 20) return 100;
    return 120;
  }

  @override
  Widget build(BuildContext context) {
    final size = _getBallSize();
    final isCompletedToday = widget.isCompleted;

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: () => widget.onToggle(!isCompletedToday),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompletedToday ? 
                Colors.green.withOpacity(0.2) : 
                Colors.grey[800],
              border: Border.all(
                color: isCompletedToday ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rive animation
                SizedBox(
                  width: size * 0.8,
                  height: size * 0.8,
                  child: RiveAnimation.asset(
                    'assets/animations/habit_ball.riv',
                    onInit: _onRiveInit,
                  ),
                ),
                // Habit info
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.completedDays.length}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: size * 0.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: size * 0.05),
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: size * 0.15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _riveController?.dispose();
    super.dispose();
  }
}