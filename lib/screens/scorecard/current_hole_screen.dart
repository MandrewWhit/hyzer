import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../models/scorecard.dart';
import 'previous_scorecards_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrentHoleScreen extends StatefulWidget {
  final Scorecard scorecard;
  final int currentHole;

  const CurrentHoleScreen({
    super.key,
    required this.scorecard,
    required this.currentHole,
  });

  @override
  State<CurrentHoleScreen> createState() => _CurrentHoleScreenState();
}

class _CurrentHoleScreenState extends State<CurrentHoleScreen> {
  late Map<String, int> _currentScores;
  bool _isSaving = false;
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);

  @override
  void initState() {
    super.initState();
    _currentScores = Map.fromIterables(
      widget.scorecard.players,
      widget.scorecard.players.map(
        (player) => widget.scorecard.scores[player]![widget.currentHole - 1],
      ),
    );
  }

  void _updateScore(String player, int score) {
    setState(() {
      _currentScores[player] = score;
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final updatedScores =
          Map<String, List<int>>.from(widget.scorecard.scores);
      _currentScores.forEach((player, score) {
        updatedScores[player]![widget.currentHole - 1] = score;
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

      if (widget.currentHole < widget.scorecard.numberOfHoles) {
        try {
          await Vibration.vibrate(duration: 50);
        } catch (e) {
          // Ignore vibration errors
        }
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CurrentHoleScreen(
              scorecard: updatedScorecard,
              currentHole: widget.currentHole + 1,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PreviousScorecardsScreen(),
          ),
          (route) => false,
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _goToPreviousHole() async {
    if (widget.currentHole > 1) {
      try {
        // Save current scores before navigating back
        final updatedScores =
            Map<String, List<int>>.from(widget.scorecard.scores);
        _currentScores.forEach((player, score) {
          updatedScores[player]![widget.currentHole - 1] = score;
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
          await Vibration.vibrate(duration: 50);
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
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
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
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Hole ${widget.currentHole}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isSaving ? null : _saveAndContinue,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scorecard.courseName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hole ${widget.currentHole} of ${widget.scorecard.numberOfHoles}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.scorecard.players.map((player) {
            return Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_currentScores[player]! > 0) {
                              _updateScore(player, _currentScores[player]! - 1);
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline,
                              color: primaryColor, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _currentScores[player].toString(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            _updateScore(player, _currentScores[player]! + 1);
                          },
                          icon: Icon(Icons.add_circle_outline,
                              color: primaryColor, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.currentHole > 1)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _goToPreviousHole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: mintColor, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Previous Hole',
                          style: TextStyle(
                            fontSize: 16,
                            overflow: TextOverflow.clip,
                          ),
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.currentHole > 1) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: mintColor, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.currentHole <
                                      widget.scorecard.numberOfHoles
                                  ? 'Next Hole'
                                  : 'Finish Scorecard',
                              style: const TextStyle(
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                              ),
                              softWrap: false,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
