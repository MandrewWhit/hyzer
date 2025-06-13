import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class Course {
  final String id;
  final String name;
  final String userId;
  final String userName;
  final Position location;
  final List<Hole> holes;
  final List<String> photos;
  final String? review;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.name,
    required this.userId,
    required this.userName,
    required this.location,
    required this.holes,
    this.photos = const [],
    this.review,
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'userName': userName,
      'location': GeoPoint(location.latitude, location.longitude),
      'holes': holes.map((hole) => hole.toMap()).toList(),
      'photos': photos,
      'review': review,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      location: Position(
        latitude: (map['location'] as GeoPoint).latitude,
        longitude: (map['location'] as GeoPoint).longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      holes: (map['holes'] as List)
          .map((hole) => Hole.fromMap(hole as Map<String, dynamic>))
          .toList(),
      photos: List<String>.from(map['photos'] ?? []),
      review: map['review'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Course copyWith({
    String? name,
    List<Hole>? holes,
    List<String>? photos,
    String? review,
    double? rating,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      userId: userId,
      userName: userName,
      location: location,
      holes: holes ?? this.holes,
      photos: photos ?? this.photos,
      review: review ?? this.review,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Hole {
  final int number;
  final Position? teeBox;
  final Position? hole;
  final int par;

  Hole({
    required this.number,
    this.teeBox,
    this.hole,
    this.par = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'teeBox':
          teeBox != null ? GeoPoint(teeBox!.latitude, teeBox!.longitude) : null,
      'hole': hole != null ? GeoPoint(hole!.latitude, hole!.longitude) : null,
      'par': par,
    };
  }

  factory Hole.fromMap(Map<String, dynamic> map) {
    return Hole(
      number: map['number'] as int,
      teeBox: map['teeBox'] != null
          ? Position(
              latitude: (map['teeBox'] as GeoPoint).latitude,
              longitude: (map['teeBox'] as GeoPoint).longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            )
          : null,
      hole: map['hole'] != null
          ? Position(
              latitude: (map['hole'] as GeoPoint).latitude,
              longitude: (map['hole'] as GeoPoint).longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            )
          : null,
      par: map['par'] as int? ?? 3,
    );
  }
}
