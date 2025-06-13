import 'package:cloud_firestore/cloud_firestore.dart';

class Scorecard {
  final String id;
  final String courseId;
  final String courseName;
  final List<String> players;
  final int numberOfHoles;
  final Map<String, List<int>> scores;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String userId;
  final int currentHole;

  Scorecard({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.players,
    required this.numberOfHoles,
    required this.scores,
    required this.createdAt,
    this.lastUpdated,
    required this.userId,
    this.currentHole = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'players': players,
      'numberOfHoles': numberOfHoles,
      'scores': scores,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'userId': userId,
      'currentHole': currentHole,
    };
  }

  factory Scorecard.fromMap(String id, Map<String, dynamic> map) {
    return Scorecard(
      id: id,
      courseId: map['courseId'] as String,
      courseName: map['courseName'] as String,
      players: List<String>.from(map['players'] as List),
      numberOfHoles: map['numberOfHoles'] as int,
      scores: Map<String, List<int>>.from(
        (map['scores'] as Map).map(
          (key, value) => MapEntry(key, List<int>.from(value as List)),
        ),
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
      userId: map['userId'] as String,
      currentHole: map['currentHole'] as int? ?? 1,
    );
  }

  Scorecard copyWith({
    String? courseName,
    List<String>? players,
    int? numberOfHoles,
    Map<String, List<int>>? scores,
    DateTime? lastUpdated,
    int? currentHole,
  }) {
    return Scorecard(
      id: id,
      courseId: courseId,
      courseName: courseName ?? this.courseName,
      players: players ?? this.players,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      scores: scores ?? this.scores,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId,
      currentHole: currentHole ?? this.currentHole,
    );
  }
}
