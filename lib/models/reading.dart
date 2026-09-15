// One row of the CSV log produced by the ESP32 (see logReading() in
// espCode/sd_card_node.ino): epoch,node_id,temperature_c,swing_c,event
class Reading {
  final int epoch; // unix seconds
  final String nodeId;
  final double temperature;
  final double swing; // max-min temperature swing within the ESP32's logging window
  final bool event; // true if swing crossed the ESP32's DELTA_THRESHOLD ("draft event")

  Reading({
    required this.epoch,
    required this.nodeId,
    required this.temperature,
    required this.swing,
    required this.event,
  });

  // Converts the raw unix-seconds epoch into a Dart DateTime for display.
  DateTime get time => DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
}
