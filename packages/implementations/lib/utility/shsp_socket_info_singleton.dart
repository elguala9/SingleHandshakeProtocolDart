import 'dart:convert';
import 'dart:io';

class ShspSocketInfoSingleton  {
  static final ShspSocketInfoSingleton _instance = ShspSocketInfoSingleton._privateConstructor();

  late final String address;
  late final int port;

  factory ShspSocketInfoSingleton() {
    return _instance;
  }

  ShspSocketInfoSingleton._privateConstructor() {
    final config = _loadConfig();
    address = config['address'] as String;
    port = config['port'] as int;
  }

  Map<String, dynamic> _loadConfig() {
    final file = File('shsp_socket_info_config.json');
    if (!file.existsSync()) {
      throw Exception('Config file shsp_socket_info_config.json not found');
    }
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
