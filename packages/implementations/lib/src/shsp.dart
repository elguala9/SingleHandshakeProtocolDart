import 'dart:io';
import 'dart:convert';
import 'package:shsp_interfaces/shsp_interfaces.dart';

/// Implementation of IShsp interface
/// Manages SHSP peer with signal and socket
class Shsp implements IShsp {
  final RawDatagramSocket _socket;
  final String _remoteIp;
  final int _remotePort;
  String _signal = '';

  Shsp({
    required RawDatagramSocket socket,
    required String remoteIp,
    required int remotePort,
  })  : _socket = socket,
        _remoteIp = remoteIp,
        _remotePort = remotePort;

  @override
  String getSignal() {
    return _signal;
  }

  @override
  void setSignal(String signal) {
    _signal = signal;
  }

  @override
  RawDatagramSocket getSocket() {
    return _socket;
  }

  @override
  String serializedObject() {
    return jsonEncode({
      'remoteIp': _remoteIp,
      'remotePort': _remotePort,
      'signal': _signal,
    });
  }

  /// Close the socket
  void close() {
    _socket.close();
  }
}
