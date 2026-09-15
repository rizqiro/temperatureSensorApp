// A saved reference to one physical ESP32 node (e.g. "Window", "Door").
// The app doesn't talk to the node's Wi-Fi radio directly here - this
// just stores the info needed to know when the phone should be able to
// reach it (ssid/password match the AP_SSID/AP_PASS in the .ino sketch)
// and where to send HTTP requests once connected (ip).
class SensorNode {
  final String id;
  String name;
  String ssid;
  String password;
  String ip; // usually 192.168.4.1 (ESP32 access point default)

  SensorNode({
    required this.id,
    required this.name,
    required this.ssid,
    required this.password,
    this.ip = '192.168.4.1',
  });

  // Serialization pair used to persist nodes with SharedPreferences
  // (see NodeStorage) since it only stores strings, not objects.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ssid': ssid,
        'password': password,
        'ip': ip,
      };

  factory SensorNode.fromJson(Map<String, dynamic> json) => SensorNode(
        id: json['id'] as String,
        name: json['name'] as String,
        ssid: json['ssid'] as String,
        password: json['password'] as String,
        ip: json['ip'] as String? ?? '192.168.4.1',
      );
}
