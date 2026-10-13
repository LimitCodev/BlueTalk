import 'package:flutter/material.dart';

void main() {
  runApp(const BlueTalkApp());
}

class BlueTalkApp extends StatelessWidget {
  const BlueTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BlueTalk',
      home: Scaffold(
        body: Center(
          child: Text('BlueTalk'),
        ),
      ),
    );
  }
}
