import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../services/node_storage.dart';
import 'add_node_screen.dart';
import 'node_dashboard_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = NodeStorage();
  List<SensorNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nodes = await _storage.loadNodes();
    setState(() => _nodes = nodes);
  }

  Future<void> _addNode() async {
    final result = await Navigator.push<SensorNode>(
      context,
      MaterialPageRoute(builder: (_) => const AddNodeScreen()),
    );
    if (result != null) {
      setState(() => _nodes.add(result));
      await _storage.saveNodes(_nodes);
    }
  }

  Future<void> _deleteNode(SensorNode node) async {
    setState(() => _nodes.removeWhere((n) => n.id == node.id));
    await _storage.saveNodes(_nodes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft sensor nodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Saved history',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: _nodes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No sensor nodes added yet.\nTap + to add your first one '
                  '(e.g. Window, Door, Reference).',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _nodes.length,
              itemBuilder: (context, index) {
                final node = _nodes[index];
                return Dismissible(
                  key: ValueKey(node.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteNode(node),
                  child: ListTile(
                    leading: const Icon(Icons.sensors),
                    title: Text(node.name),
                    subtitle: Text('Wi-Fi: ${node.ssid}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NodeDashboardScreen(node: node),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode,
        child: const Icon(Icons.add),
      ),
    );
  }
}
