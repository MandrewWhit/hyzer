import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/course.dart';

class Review {
  final String userId;
  final String userName;
  final int rating;
  final String text;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Course>> getAllCourses({int limit = 5}) async {
    try {
      final coursesSnapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return coursesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Course.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting all courses: $e');
      return [];
    }
  }

  Future<List<Course>> getNearbyCourses(Position userLocation) async {
    try {
      // Get all courses
      final coursesSnapshot = await _firestore.collection('courses').get();

      // Convert to Course objects and calculate distances
      final courses = coursesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Course.fromMap({...data, 'id': doc.id});
      }).toList();

      // Sort by distance and take top 5
      courses.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return courses.take(5).toList();
    } catch (e) {
      print('Error getting nearby courses: $e');
      return [];
    }
  }

  Future<Course> createCourse({
    required String name,
    required Position location,
    required String userId,
    required String userName,
  }) async {
    try {
      // Create initial holes list
      final holes = List.generate(
        18,
        (index) => Hole(number: index + 1),
      );

      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        userId: userId,
        userName: userName,
        location: location,
        holes: holes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('courses').doc(course.id).set(course.toMap());

      return course;
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
  }

  Future<void> updateHoleLocation({
    required String courseId,
    required int holeNumber,
    required Position location,
    required bool isTeeBox,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final courseDoc = await courseRef.get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final course = Course.fromMap({...courseDoc.data()!, 'id': courseDoc.id});
      final updatedHoles = course.holes.map((hole) {
        if (hole.number == holeNumber) {
          return Hole(
            number: hole.number,
            teeBox: isTeeBox ? location : hole.teeBox,
            hole: !isTeeBox ? location : hole.hole,
            par: hole.par,
          );
        }
        return hole;
      }).toList();

      await courseRef.update({
        'holes': updatedHoles.map((hole) => hole.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating hole location: $e');
      rethrow;
    }
  }

  Future<void> finishCourse({
    required String courseId,
    required String review,
    required double rating,
    required List<String> photos,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final courseDoc = await courseRef.get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      // Update the course with review, rating, and photos
      await courseRef.update({
        'review': review,
        'rating': rating,
        'photos': photos,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error finishing course: $e');
      rethrow;
    }
  }

  Future<void> addCoursePhoto({
    required String courseId,
    required String photoUrl,
  }) async {
    final courseRef = _firestore.collection('courses').doc(courseId);
    await courseRef.update({
      'photoUrls': FieldValue.arrayUnion([photoUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addReview({
    required String courseId,
    required String userId,
    required String userName,
    required int rating,
    required String text,
  }) async {
    final review = Review(
      userId: userId,
      userName: userName,
      rating: rating,
      text: text,
      createdAt: DateTime.now(),
    );

    final courseRef = _firestore.collection('courses').doc(courseId);
    await courseRef.update({
      'reviews': FieldValue.arrayUnion([review.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
