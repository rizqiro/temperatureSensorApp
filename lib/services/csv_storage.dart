import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// Persists exported CSV logs to the phone's own app-documents storage,
// under draft_sensor_logs/<node name>/, so they survive even after the
// log is cleared on the ESP32's SD card.
class CsvStorage {
  // Ensures (and returns) the per-node subfolder, creating it on first use.
  Future<Directory> _nodeDir(String nodeName) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/draft_sensor_logs/$nodeName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Writes a CSV export for one node, timestamped so exports never
  // overwrite each other.
  Future<File> saveCsv(String nodeName, String csvContent) async {
    final dir = await _nodeDir(nodeName);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${nodeName}_$stamp.csv');
    await file.writeAsString(csvContent);
    return file;
  }

  // Lists previously saved exports for a single node, newest first.
  Future<List<File>> listSaved(String nodeName) async {
    final dir = await _nodeDir(nodeName);
    final entries = await dir.list().toList();
    final files = entries.whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // newest first
    return files;
  }

  // Lists every saved export across all nodes, newest first. Used by the
  // "Saved history" screen.
  Future<List<File>> listAllSaved() async {
    final base = await getApplicationDocumentsDirectory();
    final root = Directory('${base.path}/draft_sensor_logs');
    if (!await root.exists()) return [];
    final all = <File>[];
    await for (final nodeDir in root.list()) {
      if (nodeDir is Directory) {
        await for (final f in nodeDir.list()) {
          if (f is File) all.add(f);
        }
      }
    }
    all.sort((a, b) => b.path.compareTo(a.path));
    return all;
  }
}
