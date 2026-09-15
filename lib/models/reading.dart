class Reading {
  final int epoch; // unix seconds
  final String nodeId;
  final double temperature;
  final double swing;
  final bool event;

  Reading({
    required this.epoch,
    required this.nodeId,
    required this.temperature,
    required this.swing,
    required this.event,
  });

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
}
