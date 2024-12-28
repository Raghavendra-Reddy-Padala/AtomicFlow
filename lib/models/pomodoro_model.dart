class PomodoroModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;
  final bool isWorkSession;
  final bool isCompleted;

  PomodoroModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.isWorkSession,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'isWorkSession': isWorkSession,
      'isCompleted': isCompleted,
    };
  }

  factory PomodoroModel.fromMap(Map<String, dynamic> map, String id) {
    return PomodoroModel(
      id: id,
      userId: map['userId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: map['duration'],
      isWorkSession: map['isWorkSession'],
      isCompleted: map['isCompleted'],
    );
  }

  PomodoroModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? isWorkSession,
    bool? isCompleted,
  }) {
    return PomodoroModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isWorkSession: isWorkSession ?? this.isWorkSession,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}