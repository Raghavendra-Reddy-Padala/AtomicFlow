class StudySessionModel {
  final String id;
  final String userId;
  final String username;
  final String? userProfileUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalMinutes;
  final bool isActive;
  final String date;
  final List<TimeSegment> timeSegments; // Track study segments

  StudySessionModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileUrl,
    required this.startTime,
    this.endTime,
    required this.totalMinutes,
    required this.isActive,
    required this.date,
    this.timeSegments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfileUrl': userProfileUrl,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalMinutes': totalMinutes,
      'isActive': isActive,
      'date': date,
      'timeSegments': timeSegments.map((segment) => segment.toMap()).toList(),
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map, String id) {
    return StudySessionModel(
      id: id,
      userId: map['userId'],
      username: map['username'],
      userProfileUrl: map['userProfileUrl'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      totalMinutes: map['totalMinutes'],
      isActive: map['isActive'],
      date: map['date'],
      timeSegments: (map['timeSegments'] as List<dynamic>?)
          ?.map((segment) => TimeSegment.fromMap(segment))
          .toList() ?? [],
    );
  }
}

class TimeSegment {
  final DateTime startTime;
  final DateTime? endTime;

  TimeSegment({
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory TimeSegment.fromMap(Map<String, dynamic> map) {
    return TimeSegment(
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }
}