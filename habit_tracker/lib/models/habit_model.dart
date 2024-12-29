class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final Map<String, bool> completionStatus; // Date string -> completion status
  final DateTime createdAt;
  final DateTime updatedAt;
  final String color; // Store color for the habit

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.completionStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'completionStatus': completionStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map, String id) {
    return HabitModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      completionStatus: Map<String, bool>.from(map['completionStatus'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      color: map['color'] ?? '#4CAF50', // Default to green
    );
  }

  HabitModel copyWith({
    String? title,
    String? description,
    Map<String, bool>? completionStatus,
    String? color,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      completionStatus: completionStatus ?? this.completionStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: color ?? this.color,
    );
  }
}