import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DraftSensorApp());
}

class DraftSensorApp extends StatelessWidget {
  const DraftSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draft Sensor',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
