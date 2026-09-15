import 'dart:convert';
import 'package:http/http.dart' as http;

class Esp32Status {
  final String nodeId;
  final double temperature;
  final int uptimeSeconds;
  final int sdFreeKb;

  Esp32Status({
    required this.nodeId,
    required this.temperature,
    required this.uptimeSeconds,
    required this.sdFreeKb,
  });

  factory Esp32Status.fromJson(Map<String, dynamic> json) => Esp32Status(
        nodeId: json['node_id']?.toString() ?? 'unknown',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        uptimeSeconds: (json['uptime_s'] as num?)?.toInt() ?? 0,
        sdFreeKb: (json['sd_free_kb'] as num?)?.toInt() ?? 0,
      );
}

/// Talks to whichever ESP32 node the phone's Wi-Fi is currently connected to.
class Esp32Client {
  final String baseUrl; // e.g. http://192.168.4.1
  Esp32Client(this.baseUrl);

  Future<Esp32Status> fetchStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/status'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) {
      throw Exception('Node returned ${res.statusCode}');
    }
    return Esp32Status.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Tells the node the current time so future log rows get real timestamps.
  Future<void> syncTime() async {
    final epoch = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    await http
        .post(
          Uri.parse('$baseUrl/settime'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'epoch': epoch}),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<List<String>> listFiles() async {
    final res = await http
        .get(Uri.parse('$baseUrl/list'))
        .timeout(const Duration(seconds: 5));
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => e.toString()).toList();
  }

  Future<String> downloadFile(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl/download?file=$path'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Download failed: ${res.statusCode}');
    }
    return res.body;
  }

  /// Erases the log file on the SD card. Only call this after confirming
  /// the data was saved successfully on the phone.
  Future<void> clearLog() async {
    await http.post(Uri.parse('$baseUrl/clear')).timeout(const Duration(seconds: 5));
  }
}
