import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/scorecard.dart';
import 'current_hole_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewScorecardScreen extends StatefulWidget {
  const NewScorecardScreen({super.key});

  @override
  State<NewScorecardScreen> createState() => _NewScorecardScreenState();
}

class _NewScorecardScreenState extends State<NewScorecardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _playerController = TextEditingController();
  final List<String> _players = [];
  int _numberOfHoles = 18;
  final Color mintColor = const Color(0xFF7BD6B6);
  final Color primaryColor = const Color(0xFF40454B);

  @override
  void dispose() {
    _courseNameController.dispose();
    _playerController.dispose();
    super.dispose();
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
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final scorecard = Scorecard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseName: _courseNameController.text,
        players: _players,
        numberOfHoles: _numberOfHoles,
        scores: Map.fromIterables(
          _players,
          List.generate(_players.length, (_) => List.filled(_numberOfHoles, 0)),
        ),
        createdAt: DateTime.now(),
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
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseNameController,
                style: TextStyle(color: mintColor),
                decoration: InputDecoration(
                  labelText: 'Course Name',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _numberOfHoles,
                style: TextStyle(color: mintColor),
                dropdownColor: primaryColor,
                decoration: InputDecoration(
                  labelText: 'Number of Holes',
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
                items: [9, 18, 27, 36].map((holes) {
                  return DropdownMenuItem(
                    value: holes,
                    child: Text('$holes holes'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _numberOfHoles = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _playerController,
                      style: TextStyle(color: mintColor),
                      decoration: InputDecoration(
                        labelText: 'Player Name',
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
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
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
                onPressed: _createScorecard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: mintColor, width: 2),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Start Scorecard',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
