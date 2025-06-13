import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../models/scorecard.dart';
import '../../services/course_service.dart';
import 'previous_scorecards_screen.dart';
import 'course_photo_upload_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CurrentHoleScreen extends StatefulWidget {
  final Scorecard scorecard;
  final int currentHole;
  final bool isNewCourse;

  const CurrentHoleScreen({
    super.key,
    required this.scorecard,
    required this.currentHole,
    required this.isNewCourse,
  });

  @override
  State<CurrentHoleScreen> createState() => _CurrentHoleScreenState();
}

class _CurrentHoleScreenState extends State<CurrentHoleScreen> {
  late Map<String, List<int>> _currentScores;
  bool _isSaving = false;
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);
  final _courseService = CourseService();

  @override
  void initState() {
    super.initState();
    _currentScores = Map.fromIterables(
      widget.scorecard.players,
      widget.scorecard.players.map(
        (player) => [widget.scorecard.scores[player]![widget.currentHole - 1]],
      ),
    );
  }

  void _updateScore(String player, int score) {
    setState(() {
      _currentScores[player] = [score];
    });
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final scorecardRef = FirebaseFirestore.instance
          .collection('scorecards')
          .doc(widget.scorecard.id);

      // Create a new scorecard with updated scores
      final updatedScores =
          Map<String, List<int>>.from(widget.scorecard.scores);
      _currentScores.forEach((player, score) {
        updatedScores[player]![widget.currentHole - 1] = score[0];
      });

      final updatedScorecard = widget.scorecard.copyWith(
        scores: updatedScores,
        lastUpdated: DateTime.now(),
      );

      if (widget.currentHole < 18) {
        // Use set with merge instead of update
        await scorecardRef.set({
          'scores': updatedScores,
          'lastUpdated': Timestamp.fromDate(updatedScorecard.lastUpdated!),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CurrentHoleScreen(
                scorecard: updatedScorecard,
                currentHole: widget.currentHole + 1,
                isNewCourse: widget.isNewCourse,
              ),
            ),
          );
        }
      } else {
        // Last hole - update scores and finish scorecard
        await scorecardRef.set({
          'scores': updatedScores,
          'isComplete': true,
          'lastUpdated': Timestamp.fromDate(updatedScorecard.lastUpdated!),
        }, SetOptions(merge: true));

        if (mounted) {
          if (widget.isNewCourse) {
            // Show dialog to upload course photos
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Upload Course Photos'),
                content: const Text(
                  'Would you like to upload photos of the course now? '
                  'You can also do this later from the course details screen.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Return to home screen
                    },
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoursePhotoUploadScreen(
                            courseId: widget.scorecard.courseId,
                            courseName: widget.scorecard.courseName,
                          ),
                        ),
                      );
                    },
                    child: const Text('Upload Now'),
                  ),
                ],
              ),
            );
          } else {
            Navigator.pop(context); // Return to home screen
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scorecard: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _goToPreviousHole() async {
    if (widget.currentHole > 1) {
      try {
        // Save current scores before navigating back
        final updatedScores =
            Map<String, List<int>>.from(widget.scorecard.scores);
        _currentScores.forEach((player, score) {
          updatedScores[player]![widget.currentHole - 1] = score[0];
        });

        final updatedScorecard = widget.scorecard.copyWith(
          scores: updatedScores,
          lastUpdated: DateTime.now(),
        );

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('scorecards')
            .doc(updatedScorecard.id)
            .set(updatedScorecard.toMap());

        try {
          if (await Vibration.hasVibrator() ?? false) {
            await Vibration.vibrate(duration: 50);
          }
        } catch (e) {
          // Ignore vibration errors
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CurrentHoleScreen(
                scorecard: updatedScorecard,
                currentHole: widget.currentHole - 1,
                isNewCourse: widget.isNewCourse,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving scorecard: $e')),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // For balance
                  Text(
                    'Hole ${widget.currentHole}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: _isSaving ? null : _saveAndContinue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.isNewCourse) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Mark Hole Locations',
                      style: TextStyle(
                        color: mintColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final position =
                                    await Geolocator.getCurrentPosition();
                                await _courseService.updateHoleLocation(
                                  courseId: widget.scorecard.courseId,
                                  holeNumber: widget.currentHole,
                                  location: position,
                                  isTeeBox: true,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tee box location saved'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error saving tee box location: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.golf_course),
                            label: const Text('I am at the tee box'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mintColor,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final position =
                                    await Geolocator.getCurrentPosition();
                                await _courseService.updateHoleLocation(
                                  courseId: widget.scorecard.courseId,
                                  holeNumber: widget.currentHole,
                                  location: position,
                                  isTeeBox: false,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hole location saved'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error saving hole location: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.flag),
                            label: const Text('I am at the hole'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mintColor,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.scorecard.players.length,
                itemBuilder: (context, index) {
                  final player = widget.scorecard.players[index];
                  return Card(
                    color: primaryColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: mintColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _currentScores[player]?[0].toString() ??
                                          '0',
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: mintColor),
                                  decoration: InputDecoration(
                                    labelText: 'Score',
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
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
                                  onChanged: (value) {
                                    setState(() {
                                      _currentScores[player] = [
                                        int.tryParse(value) ?? 0
                                      ];
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        widget.currentHole > 1 ? _goToPreviousHole : null,
                    style: TextButton.styleFrom(
                      foregroundColor: mintColor,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color:
                              widget.currentHole > 1 ? mintColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hole ${widget.currentHole - 1}',
                          style: TextStyle(
                            color: widget.currentHole > 1
                                ? mintColor
                                : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.currentHole < 18
                        ? _saveAndContinue
                        : _saveAndContinue,
                    style: TextButton.styleFrom(
                      foregroundColor: mintColor,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.currentHole < 18
                              ? 'Hole ${widget.currentHole + 1}'
                              : 'Finish',
                          style: TextStyle(
                            color: mintColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: mintColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
