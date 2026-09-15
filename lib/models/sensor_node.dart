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
