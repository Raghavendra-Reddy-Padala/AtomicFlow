import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/models/user_model.dart';
import 'package:habit_tracker/providers/study_timer_provider.dart';
import 'package:habit_tracker/services/study_room_services.dart';
import '../services/user_service.dart';
import 'package:habit_tracker/models/study_session_model.dart';

class StudyRoom extends ConsumerStatefulWidget {
  const StudyRoom({super.key});

  @override
  ConsumerState<StudyRoom> createState() => _StudyRoomState();
}

class _StudyRoomState extends ConsumerState<StudyRoom> {
  Timer? _updateTimer;
  UserModel? _currentUser;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserProfile();
    if (_userId != null) {
      _restoreSession();
    }
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateStudyTime();
    });
  }

  void _updateStudyTime() {
    if (_userId == null) return;
    
    final timerState = ref.read(studyTimerProvider.notifier).state[_userId];
    if (timerState?.isRunning == true && timerState?.sessionId != null) {
      ref.read(studyRoomServiceProvider).updateSessionTime(
            timerState!.sessionId!,
            timerState.elapsedSeconds ~/ 60,
          );
    }
  }
  Future<void> _restoreSession() async {
    if (_userId == null) return;

    final session = await ref.read(studyRoomServiceProvider).getCurrentSession(_userId!);
    if (session != null && session.isActive) {
      final lastSegment = session.timeSegments.last;
      final elapsedSeconds = DateTime.now().difference(lastSegment.startTime).inSeconds;
      
      ref.read(studyTimerProvider.notifier).setSessionId(_userId!, session.id);
      final newState = StudyTimerState(
        elapsedSeconds: elapsedSeconds,
        isRunning: true,
        sessionId: session.id,
      );
      
      ref.read(studyTimerProvider.notifier).state = {
        ...ref.read(studyTimerProvider.notifier).state,
        _userId!: newState,
      };
    }
  }

  Future<void> _loadUserProfile() async {
    final userService = ref.read(userServiceProvider);
    if (_userId != null) {
      _currentUser = await userService.getUserProfile(_userId!);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[400]!; // Silver
      case 2:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(studyTimerProvider)[_userId ?? ''] ?? StudyTimerState();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<StudySessionModel?>(
          stream: ref.watch(studyRoomServiceProvider).getCurrentUserSession(),
          builder: (context, sessionSnapshot) {
            return Column(
              children: [
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentUser != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: _currentUser?.profileImageUrl != null
                                    ? NetworkImage(_currentUser!.profileImageUrl!)
                                    : null,
                                child: _currentUser?.profileImageUrl == null
                                    ? Icon(Icons.person, color: colorScheme.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currentUser!.username,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          _formatTime(timerState.elapsedSeconds),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _currentUser == null
                                  ? null
                                  : () async {
                                      if (!timerState.isRunning) {
                                        final sessionId = await ref
                                            .read(studyRoomServiceProvider)
                                            .startSession(_currentUser!);
                                        ref
                                            .read(studyTimerProvider.notifier)
                                            .setSessionId(_userId!, sessionId);
                                        ref.read(studyTimerProvider.notifier).startTimer(_userId!);
                                      } else {
                                        if (timerState.sessionId != null) {
                                          await ref
                                              .read(studyRoomServiceProvider)
                                              .pauseSession(timerState.sessionId!);
                                        }
                                        ref.read(studyTimerProvider.notifier).pauseTimer(_userId!);
                                      }
                                    },
                              icon: Icon(
                                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                              ),
                              label: Text(
                                timerState.isRunning ? 'Pause' : 'Start',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            if (sessionSnapshot.hasData && !timerState.isRunning) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (_userId != null) {
                                    await ref
                                        .read(studyRoomServiceProvider)
                                        .endSession(sessionSnapshot.data!.id);
                                    ref.read(studyTimerProvider.notifier).resetTimer(_userId!);
                                  }
                                },
                                icon: const Icon(Icons.stop),
                                label: Text(
                                  'End Session',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Today\'s Rankings',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder(
                    stream: ref.watch(studyRoomServiceProvider).getDailyRankings(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sessions = snapshot.data!;
                      if (sessions.isEmpty) {
                        return Center(
                          child: Text(
                            'No study sessions today',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: sessions.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: index < 3 ? _getRankColor(index) : null,
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                session.username,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '${session.totalMinutes} mins',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}