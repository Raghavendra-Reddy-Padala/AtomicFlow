import 'package:cloud_firestore/cloud_firestore.dart';

// App Settings Model for Firebase
class AppSettings {
  String? id;
  DateTime? firstLaunchDate;

  AppSettings({this.id, this.firstLaunchDate});

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'firstLaunchDate': firstLaunchDate != null 
        ? Timestamp.fromDate(firstLaunchDate!) 
        : null,
    };
  }

  // Create from Firestore document
  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppSettings(
      id: doc.id,
      firstLaunchDate: data['firstLaunchDate'] != null 
        ? (data['firstLaunchDate'] as Timestamp).toDate()
        : null,
    );
  }
}

// Habit Model for Firebase
class Habit {
  String id; // Firebase uses string ID
  String name;
  List<DateTime> completedDays;
  String userId; // Added to track user-specific habits

  Habit({
    required this.id,
    required this.name,
    required this.userId,
    List<DateTime>? completedDays,
  }) : completedDays = completedDays ?? [];

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'completedDays': completedDays
        .map((date) => Timestamp.fromDate(date))
        .toList(),
    };
  }

  // Create from Firestore document
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      completedDays: (data['completedDays'] as List?)
        ?.map((timestamp) => (timestamp as Timestamp).toDate())
        .toList() ?? [],
    );
  }
}