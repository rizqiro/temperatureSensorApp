import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sensor_node.dart';

class AddNodeScreen extends StatefulWidget {
  const AddNodeScreen({super.key});

  @override
  State<AddNodeScreen> createState() => _AddNodeScreenState();
}

class _AddNodeScreenState extends State<AddNodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ipCtrl = TextEditingController(text: '192.168.4.1');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final node = SensorNode(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      ssid: _ssidCtrl.text.trim(),
      password: _passCtrl.text,
      ip: _ipCtrl.text.trim().isEmpty ? '192.168.4.1' : _ipCtrl.text.trim(),
    );
    Navigator.pop(context, node);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add sensor node')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Position name (e.g. Window, Door)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ssidCtrl,
                decoration: const InputDecoration(
                  labelText: 'Wi-Fi name (AP_SSID from the ESP32 sketch)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Wi-Fi password (AP_PASS from the sketch)',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Node IP (usually 192.168.4.1)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Save node'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
