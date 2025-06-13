import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../scorecard/new_scorecard_screen.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  final _courseService = CourseService();
  final _courseNameController = TextEditingController();
  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCourses = true;
  int _currentLimit = 5;
  Position? _userLocation;
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = position;
      });
      await _loadCourses();
    } catch (e) {
      print('Error getting location: $e');
      // If location is not available, load all courses
      await _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    try {
      final courses = _userLocation != null
          ? await _courseService.getNearbyCourses(_userLocation!)
          : await _courseService.getAllCourses(limit: _currentLimit);

      setState(() {
        _courses = courses;
        _isLoading = false;
        _hasMoreCourses = courses.length == _currentLimit;
      });
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoading = false;
        _hasMoreCourses = false;
      });
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreCourses) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentLimit += 5;
      final moreCourses =
          await _courseService.getAllCourses(limit: _currentLimit);

      setState(() {
        _courses = moreCourses;
        _hasMoreCourses = moreCourses.length == _currentLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more courses: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  String _formatDistance(Course course) {
    if (_userLocation == null) return 'Distance unknown';

    final distance = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          course.location.latitude,
          course.location.longitude,
        ) /
        1609.34; // Convert meters to miles

    if (distance < 1) {
      return '${(distance * 5280).toStringAsFixed(0)} ft';
    }
    return '${distance.toStringAsFixed(1)} mi';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous';

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select a Course',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _courses.length +
                      2, // +1 for load more button, +1 for create button space
                  itemBuilder: (context, index) {
                    if (index == _courses.length) {
                      // Load More button
                      if (!_hasMoreCourses) {
                        return const SizedBox(
                            height: 80); // Space for the fixed button
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: _isLoadingMore ? null : _loadMoreCourses,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : const Text('Load More Courses'),
                        ),
                      );
                    }
                    if (index == _courses.length + 1) {
                      return const SizedBox(
                          height: 80); // Space for the fixed button
                    }

                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewScorecardScreen(
                                selectedCourse: course,
                                isCreatingCourse: false,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (course.photos.isNotEmpty)
                              Image.network(
                                course.photos.first,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[800],
                                    child: Center(
                                      child: Icon(
                                        Icons.golf_course,
                                        size: 100,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                height: 200,
                                color: Colors.grey[800],
                                child: Center(
                                  child: Icon(
                                    Icons.golf_course,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (course.rating > 0) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: mintColor, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          course.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (course.review != null) ...[
                                    Text(
                                      course.review!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Fixed Create New Course button at the bottom
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Create New Course'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Enter the name of your new course. You will be able to mark the locations of each hole as you play.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _courseNameController,
                            decoration: const InputDecoration(
                              labelText: 'Course Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (_courseNameController.text.isNotEmpty) {
                              if (_userLocation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Location services must be enabled to create a new course.'),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                                return;
                              }

                              try {
                                // Create the course in Firebase
                                final course =
                                    await _courseService.createCourse(
                                  name: _courseNameController.text,
                                  location: _userLocation!,
                                  userId: user?.uid ?? '',
                                  userName: userName,
                                );

                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NewScorecardScreen(
                                        selectedCourse: course,
                                        isCreatingCourse: true,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Error creating course: $e'),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mintColor,
                  foregroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
