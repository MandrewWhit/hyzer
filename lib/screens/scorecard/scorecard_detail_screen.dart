import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/scorecard.dart';
import 'current_hole_screen.dart';

class ScorecardDetailScreen extends StatefulWidget {
  final Scorecard scorecard;

  const ScorecardDetailScreen({
    super.key,
    required this.scorecard,
  });

  @override
  State<ScorecardDetailScreen> createState() => _ScorecardDetailScreenState();
}

class _ScorecardDetailScreenState extends State<ScorecardDetailScreen> {
  late TextEditingController _courseNameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _courseNameController =
        TextEditingController(text: widget.scorecard.courseName);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updatedScorecard = widget.scorecard.copyWith(
      courseName: _courseNameController.text,
      lastUpdated: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('scorecards')
        .doc(updatedScorecard.id)
        .update(updatedScorecard.toMap());

    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveChanges,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: _courseNameController,
                          decoration: const InputDecoration(
                            labelText: 'Course Name',
                            border: OutlineInputBorder(),
                          ),
                        )
                      else
                        Text(
                          widget.scorecard.courseName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Scores',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            const DataColumn(label: Text('Hole')),
                            ...widget.scorecard.players.map(
                              (player) => DataColumn(label: Text(player)),
                            ),
                          ],
                          rows: List.generate(
                            widget.scorecard.numberOfHoles,
                            (holeIndex) {
                              return DataRow(
                                cells: [
                                  DataCell(Text('${holeIndex + 1}')),
                                  ...widget.scorecard.players.map(
                                    (player) => DataCell(
                                      Text(
                                        widget.scorecard
                                            .scores[player]![holeIndex]
                                            .toString(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CurrentHoleScreen(
                        scorecard: widget.scorecard,
                        currentHole: 1,
                      ),
                    ),
                  );
                },
                child: const Text('Update Scorecard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
