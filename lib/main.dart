import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const BlueTalkApp());
}

class BlueTalkApp extends StatelessWidget {
  const BlueTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueTalk',
      theme: buildBlueTalkTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('BlueTalk'),
        ),
      ),
    );
  }
}
