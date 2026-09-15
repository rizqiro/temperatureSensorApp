import '../models/reading.dart';

class CsvParser {
  /// Parses raw CSV text from the ESP32 (header: epoch,node_id,temperature_c,swing_c,event)
  static List<Reading> parse(String csvContent) {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];
    final readings = <Reading>[];
    for (var i = 1; i < lines.length; i++) {
      // skip header row
      final parts = lines[i].split(',');
      if (parts.length < 5) continue;
      final epoch = int.tryParse(parts[0].trim());
      if (epoch == null) continue;
      readings.add(Reading(
        epoch: epoch,
        nodeId: parts[1].trim(),
        temperature: double.tryParse(parts[2].trim()) ?? 0,
        swing: double.tryParse(parts[3].trim()) ?? 0,
        event: parts[4].trim() == '1',
      ));
    }
    readings.sort((a, b) => a.epoch.compareTo(b.epoch));
    return readings;
  }

  /// Converts readings back into CSV text (adds a human-readable timestamp column).
  static String toCsv(List<Reading> readings) {
    final buffer = StringBuffer('epoch,timestamp,node_id,temperature_c,swing_c,event\n');
    for (final r in readings) {
      buffer.writeln('${r.epoch},${r.time.toIso8601String()},${r.nodeId},'
          '${r.temperature.toStringAsFixed(2)},${r.swing.toStringAsFixed(2)},${r.event ? 1 : 0}');
    }
    return buffer.toString();
  }
}
