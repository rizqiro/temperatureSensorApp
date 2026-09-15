import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sensor_node.dart';
import '../models/reading.dart';
import '../models/timeframe.dart';
import '../services/esp32_client.dart';
import '../services/csv_parser.dart';
import '../services/csv_storage.dart';
import '../services/stats.dart';

class NodeDashboardScreen extends StatefulWidget {
  final SensorNode node;
  const NodeDashboardScreen({super.key, required this.node});

  @override
  State<NodeDashboardScreen> createState() => _NodeDashboardScreenState();
}

class _NodeDashboardScreenState extends State<NodeDashboardScreen> {
  bool _connecting = false;
  bool _connected = false;
  String _message = '';
  List<Reading> _allReadings = [];
  Timeframe _timeframe = Timeframe.h4;
  String? _lastExportPath;

  Future<void> _connectAndLoad() async {
    setState(() {
      _connecting = true;
      _message = 'Connecting to ${widget.node.name}...';
    });
    try {
      final client = Esp32Client('http://${widget.node.ip}');
      await client.fetchStatus(); // confirms the node is reachable
      await client.syncTime();
      final files = await client.listFiles();
      if (files.isEmpty) {
        setState(() {
          _connected = true;
          _message = 'Connected, but no log file on the node yet.';
        });
        return;
      }
      final csv = await client.downloadFile(files.first);
      final readings = CsvParser.parse(csv);
      setState(() {
        _allReadings = readings;
        _connected = true;
        _lastExportPath = null;
        _message = readings.isEmpty
            ? 'Connected, but the log is empty.'
            : 'Loaded ${readings.length} readings.';
      });
    } catch (e) {
      setState(() {
        _connected = false;
        _message = 'Could not reach ${widget.node.name}. Make sure your '
            'phone\'s Wi-Fi is connected to "${widget.node.ssid}".';
      });
    } finally {
      setState(() => _connecting = false);
    }
  }

  Future<void> _refresh() => _connectAndLoad();

  List<Reading> get _visibleReadings => filterByTimeframe(_allReadings, _timeframe.duration);

  Future<void> _exportCsv() async {
    final rows = _visibleReadings;
    if (rows.isEmpty) return;
    final csv = CsvParser.toCsv(rows);
    final saved = await CsvStorage().saveCsv('${widget.node.name}_${_timeframe.label}', csv);
    setState(() {
      _lastExportPath = saved.path;
      _message = 'Exported ${rows.length} rows (${_timeframe.label}).';
    });
  }

  Future<void> _shareLastExport() async {
    if (_lastExportPath == null) return;
    await Share.shareXFiles(
      [XFile(_lastExportPath!)],
      text: '${widget.node.name} draft sensor log (${_timeframe.label})',
    );
  }

  Future<void> _clearOnDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear log on device?'),
        content: const Text(
          'This erases the CSV stored on the SD card. Only do this after '
          "you've exported the data you need.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final client = Esp32Client('http://${widget.node.ip}');
      await client.clearLog();
      setState(() => _message = 'Log cleared on the device.');
    } catch (e) {
      setState(() => _message = 'Could not clear log: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ReadingStats.fromReadings(_visibleReadings);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.node.name),
        actions: [
          if (_connected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _connecting ? null : _refresh,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearOnDevice();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear log on device')),
            ],
          ),
        ],
      ),
      body: _connected ? _buildDashboard(stats) : _buildConnectCard(),
    );
  }

  Widget _buildConnectCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Open Wi-Fi settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('2. Connect to "${widget.node.ssid}"'),
                  const SizedBox(height: 4),
                  const Text('3. Come back here and tap Connect'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _connecting ? null : _connectAndLoad,
            icon: const Icon(Icons.wifi_find),
            label: Text(_connecting ? 'Connecting...' : 'Connect'),
          ),
          const SizedBox(height: 16),
          if (_message.isNotEmpty) Text(_message),
        ],
      ),
    );
  }

  Widget _buildDashboard(ReadingStats? stats) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (stats == null)
            Text(_message.isEmpty ? 'No readings in this time range yet.' : _message)
          else ...[
            Row(
              children: [
                Expanded(child: _statCard('Current', '${stats.current.toStringAsFixed(1)} C', null)),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    'Max',
                    '${stats.max.toStringAsFixed(1)} C',
                    DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(stats.maxEpoch * 1000)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    'Min',
                    '${stats.min.toStringAsFixed(1)} C',
                    DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(stats.minEpoch * 1000)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _timeframeSelector(),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: _buildChart()),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _visibleReadings.isEmpty ? null : _exportCsv,
              icon: const Icon(Icons.download),
              label: Text('Export CSV (${_timeframe.label})'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _lastExportPath == null ? null : _shareLastExport,
              icon: const Icon(Icons.share),
              label: const Text('Share to WhatsApp'),
            ),
          ],
          const SizedBox(height: 16),
          if (_message.isNotEmpty)
            Text(_message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String? time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (time != null) ...[
            const SizedBox(height: 2),
            Text('at $time', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _timeframeSelector() {
    return Wrap(
      spacing: 8,
      children: Timeframe.values.map((tf) {
        final selected = tf == _timeframe;
        return ChoiceChip(
          label: Text(tf.label),
          selected: selected,
          onSelected: (_) => setState(() => _timeframe = tf),
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    final rows = _visibleReadings;
    if (rows.isEmpty) {
      return const Center(child: Text('No data in this range'));
    }
    final spots = rows.map((r) => FlSpot(r.epoch.toDouble(), r.temperature)).toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final interval = ((maxX - minX) / 4).clamp(60, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        minX: minX,
        maxX: maxX,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) =>
                  Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(DateFormat('HH:mm').format(dt), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0x1A0F6E56)),
          ),
        ],
      ),
    );
  }
}
