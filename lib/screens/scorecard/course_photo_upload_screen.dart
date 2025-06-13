import 'package:flutter/material.dart';
import '../../services/course_service.dart';

class CoursePhotoUploadScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CoursePhotoUploadScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CoursePhotoUploadScreen> createState() =>
      _CoursePhotoUploadScreenState();
}

class _CoursePhotoUploadScreenState extends State<CoursePhotoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final _courseService = CourseService();
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);

  double _rating = 0.0;
  bool _isUploading = false;

  Future<void> _finishCourse() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the course'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _courseService.finishCourse(
        courseId: widget.courseId,
        review: _reviewController.text,
        rating: _rating,
        photos: [], // Empty photos list for now
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course finished successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
        // Pop all screens until we reach the home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.courseName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // For balance
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Rate the Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: mintColor,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _reviewController,
                maxLines: 5,
                style: TextStyle(color: mintColor),
                decoration: InputDecoration(
                  labelText: 'Write a Review',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: mintColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: mintColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: mintColor),
                  ),
                  fillColor: primaryColor,
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _finishCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: mintColor, width: 2),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  _isUploading ? 'Saving...' : 'Finish Course',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
