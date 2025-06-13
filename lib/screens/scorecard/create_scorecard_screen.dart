import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/scorecard.dart';
import '../../models/course.dart';
import '../../utils/location_permissions.dart';
import 'current_hole_screen.dart';

class CreateScorecardScreen extends StatefulWidget {
  const CreateScorecardScreen({super.key});

  @override
  State<CreateScorecardScreen> createState() => _CreateScorecardScreenState();
}

class _CreateScorecardScreenState extends State<CreateScorecardScreen> {
  bool _isCreating = false;
  Course? _selectedCourse;
  List<String> _selectedPlayers = [];

  Future<void> _createScorecard() async {
    if (_isCreating) return;

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    if (_selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player')),
      );
      return;
    }

    // Check if this is a new course and location is required
    if (_selectedCourse!.isNew) {
      final isLocationEnabled = await LocationPermissions.isLocationEnabled();
      if (!isLocationEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services must be enabled to create a new course.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Request location permission for new courses
      final hasPermission =
          await LocationPermissions.checkAndRequestPermission(context);
      if (!hasPermission) {
        return; // The permission utility will show appropriate messages
      }
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final scorecard = Scorecard(
        id: '',
        courseId: _selectedCourse!.id,
        courseName: _selectedCourse!.name,
        players: _selectedPlayers,
        scores: List.generate(
          18,
          (_) => List.filled(_selectedPlayers.length, 0),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isComplete: false,
        currentHole: 1,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('scorecards')
          .add(scorecard.toMap());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CurrentHoleScreen(
              scorecard: scorecard.copyWith(id: docRef.id),
              isNewCourse: _selectedCourse!.isNew,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating scorecard: $e')),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Create Scorecard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course selection
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading courses');
                }

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final courses = snapshot.data!.docs
                    .map((doc) => Course.fromFirestore(doc))
                    .toList();

                return DropdownButtonFormField<Course>(
                  value: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course.name),
                    );
                  }).toList(),
                  onChanged: (Course? value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Player selection
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading players');
                }

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final players = snapshot.data!.docs
                    .map((doc) => doc['name'] as String)
                    .toList();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Players'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: players.map((player) {
                          final isSelected = _selectedPlayers.contains(player);
                          return FilterChip(
                            label: Text(player),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPlayers.add(player);
                                } else {
                                  _selectedPlayers.remove(player);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isCreating ? null : _createScorecard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : const Text('Create Scorecard'),
            ),
          ],
        ),
      ),
    );
  }
}
