// App entry point. This is a companion app for the ESP32 draft sensor
// nodes (see espCode/sd_card_node.ino): each node broadcasts its own
// Wi-Fi access point, and this app connects to whichever node the
// phone is currently on to pull down temperature logs.
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DraftSensorApp());
}

// Root widget: just sets up the MaterialApp theme and starts on the
// list of saved sensor nodes (HomeScreen).
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
