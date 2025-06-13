import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../models/course.dart';
import '../../models/scorecard.dart';
import 'current_hole_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewScorecardScreen extends StatefulWidget {
  final Course? selectedCourse;
  final bool isCreatingCourse;

  const NewScorecardScreen({
    super.key,
    this.selectedCourse,
    this.isCreatingCourse = false,
  });

  @override
  State<NewScorecardScreen> createState() => _NewScorecardScreenState();
}

class _NewScorecardScreenState extends State<NewScorecardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _playerController = TextEditingController();
  final List<String> _players = [];
  int _numberOfHoles = 18;
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);
  final _courseService = CourseService();
  final _authService = AuthService();

  bool _isLoading = true;
  Position? _userLocation;

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
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addPlayer() {
    if (_playerController.text.isNotEmpty) {
      setState(() {
        _players.add(_playerController.text);
        _playerController.clear();
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  Future<void> _createScorecard() async {
    if (_formKey.currentState!.validate() && _players.isNotEmpty) {
      final userId = _authService.currentUser!.uid;
      final scorecard = Scorecard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: widget.selectedCourse?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        courseName: widget.selectedCourse?.name ?? 'New Course',
        players: _players,
        numberOfHoles: _numberOfHoles,
        scores: Map.fromIterables(
          _players,
          List.generate(_players.length, (_) => List.filled(_numberOfHoles, 0)),
        ),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        userId: userId,
      );

      try {
        // Save to Firestore first
        await FirebaseFirestore.instance
            .collection('scorecards')
            .doc(scorecard.id)
            .set(scorecard.toMap());

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CurrentHoleScreen(
                scorecard: scorecard,
                currentHole: 1,
                isNewCourse: widget.isCreatingCourse,
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
                  const SizedBox(width: 8),
                  Text(
                    widget.selectedCourse?.name ?? 'New Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _playerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Add Player',
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
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _addPlayer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_players.isNotEmpty) ...[
                      const Text(
                        'Players:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_players.length, (index) {
                        return ListTile(
                          title: Text(
                            _players[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.white),
                            onPressed: () => _removePlayer(index),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _players.isNotEmpty ? _createScorecard : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: mintColor, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _isLoading ? 'Loading...' : 'Start Scorecard',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
