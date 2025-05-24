import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/scorecard.dart';
import 'scorecard_detail_screen.dart';
import '../home/home_screen.dart';

const Color primaryColor = Color(0xFF2D3436);

class PreviousScorecardsScreen extends StatefulWidget {
  const PreviousScorecardsScreen({super.key});

  @override
  State<PreviousScorecardsScreen> createState() =>
      _PreviousScorecardsScreenState();
}

class _PreviousScorecardsScreenState extends State<PreviousScorecardsScreen> {
  @override
  void initState() {
    super.initState();
    // Force a refresh when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser!.uid;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('scorecards')
                    .where('userId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final scorecards = snapshot.data!.docs.map((doc) {
                    return Scorecard.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (scorecards.isEmpty) {
                    return const Center(
                      child: Text('No scorecards yet'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: scorecards.length,
                      itemBuilder: (context, index) {
                        final scorecard = scorecards[index];
                        return Card(
                          child: ListTile(
                            title: Text(scorecard.courseName),
                            subtitle: Text(
                              '${scorecard.players.length} players • ${scorecard.numberOfHoles} holes\n'
                              'Created: ${_formatDate(scorecard.createdAt)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScorecardDetailScreen(
                                    scorecard: scorecard,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
