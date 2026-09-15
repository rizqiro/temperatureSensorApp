import '../models/reading.dart';

// Summary values shown at the top of the node dashboard: latest, highest,
// and lowest temperature (plus when the high/low occurred) within
// whatever set of readings is passed in (already timeframe-filtered).
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

  // Returns null when there's nothing to summarize (e.g. no readings
  // loaded yet, or the selected timeframe filtered everything out).
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
