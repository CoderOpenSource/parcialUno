import 'package:flutter/material.dart';

class MoodWidget extends StatelessWidget {
  final String mood;
  final IconData moodIcon;

  const MoodWidget({super.key, required this.mood, required this.moodIcon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(moodIcon, size: 40.0),
      title: Text("You're feeling $mood!"),
      subtitle: const Text("Here's some music for your mood..."),
    );
  }
}
