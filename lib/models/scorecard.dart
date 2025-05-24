import 'package:cloud_firestore/cloud_firestore.dart';

class Scorecard {
  final String id;
  final String courseName;
  final List<String> players;
  final int numberOfHoles;
  final Map<String, List<int>> scores;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String userId;

  Scorecard({
    required this.id,
    required this.courseName,
    required this.players,
    required this.numberOfHoles,
    required this.scores,
    required this.createdAt,
    this.lastUpdated,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'players': players,
      'numberOfHoles': numberOfHoles,
      'scores': scores,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'userId': userId,
    };
  }

  factory Scorecard.fromMap(String id, Map<String, dynamic> map) {
    return Scorecard(
      id: id,
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
    );
  }

  Scorecard copyWith({
    String? courseName,
    List<String>? players,
    int? numberOfHoles,
    Map<String, List<int>>? scores,
    DateTime? lastUpdated,
  }) {
    return Scorecard(
      id: id,
      courseName: courseName ?? this.courseName,
      players: players ?? this.players,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      scores: scores ?? this.scores,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId,
    );
  }
}
