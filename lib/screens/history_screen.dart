import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/csv_storage.dart';

// Lists every CSV export previously saved to the phone (across all
// nodes) and lets the user re-share any of them (e.g. via WhatsApp)
// without needing to reconnect to the ESP32.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Loads every saved export file from local storage (newest first).
  Future<void> _load() async {
    final files = await CsvStorage().listAllSaved();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  // Opens the OS share sheet for a single saved CSV file.
  Future<void> _share(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: file.path.split('/').last);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved logs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('No saved logs yet.'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final name = file.path.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(name),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _share(file),
                      ),
                    );
                  },
                ),
    );
  }
}
