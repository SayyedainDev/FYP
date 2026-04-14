import 'package:flutter/material.dart';

class StudentLeaderboardScreen extends StatelessWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(title: Text('#1 — Student')),
          ListTile(title: Text('#2 — Student')),
          ListTile(title: Text('#3 — Student')),
          Divider(),
          ListTile(title: Text('You — #4 in class')),
        ],
      ),
    );
  }
}
