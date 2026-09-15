import '../models/reading.dart';

class ReadingStats {
  final double current;
  final double max;
  final int maxEpoch;
  final double min;
  final int minEpoch;

  ReadingStats({
    required this.current,
    required this.max,
    required this.maxEpoch,
    required this.min,
    required this.minEpoch,
  });

  static ReadingStats? fromReadings(List<Reading> readings) {
    if (readings.isEmpty) return null;
    var maxR = readings.first;
    var minR = readings.first;
    for (final r in readings) {
      if (r.temperature > maxR.temperature) maxR = r;
      if (r.temperature < minR.temperature) minR = r;
    }
    return ReadingStats(
      current: readings.last.temperature,
      max: maxR.temperature,
      maxEpoch: maxR.epoch,
      min: minR.temperature,
      minEpoch: minR.epoch,
    );
  }
}

/// Keeps only readings within [window] of the most recent reading.
/// A null window (Timeframe.all) returns everything unchanged.
List<Reading> filterByTimeframe(List<Reading> readings, Duration? window) {
  if (window == null || readings.isEmpty) return readings;
  final latestEpoch = readings.last.epoch;
  final cutoff = latestEpoch - window.inSeconds;
  return readings.where((r) => r.epoch >= cutoff).toList();
}
