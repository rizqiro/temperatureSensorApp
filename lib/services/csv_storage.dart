import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CsvStorage {
  Future<Directory> _nodeDir(String nodeName) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/draft_sensor_logs/$nodeName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> saveCsv(String nodeName, String csvContent) async {
    final dir = await _nodeDir(nodeName);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${nodeName}_$stamp.csv');
    await file.writeAsString(csvContent);
    return file;
  }

  Future<List<File>> listSaved(String nodeName) async {
    final dir = await _nodeDir(nodeName);
    final entries = await dir.list().toList();
    final files = entries.whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // newest first
    return files;
  }

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
