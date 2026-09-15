import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_node.dart';

class NodeStorage {
  static const _key = 'sensor_nodes';

  Future<List<SensorNode>> loadNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => SensorNode.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNodes(List<SensorNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(nodes.map((n) => n.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
