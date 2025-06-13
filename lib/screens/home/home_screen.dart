import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../course/course_selection_screen.dart';
import '../scorecard/previous_scorecards_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/hyzer-logo-removebg-preview.png',
                    height: 40,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Provider.of<AuthService>(context, listen: false)
                          .signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseSelectionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'New Scorecard',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreviousScorecardsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Previous Scorecards',
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
