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

  /// Factory constructor - creates a Shsp instance with optional signal
  /// 
  /// This factory method:
  /// - Creates a new Shsp instance wrapping a RawDatagramSocket
  /// - Initializes the remote peer information (IP and port)
  /// - Sets up an optional handshake signal
  /// - Provides a simplified interface for socket management
  /// 
  /// Parameters:
  ///   - [socket]: The raw datagram socket for UDP communication
  ///   - [remoteIp]: The remote peer's IP address as a string
  ///   - [remotePort]: The remote peer's port number
  ///   - [signal]: Optional handshake signal (default: empty string)
  /// 
  /// Returns: A new Shsp instance for low-level protocol communication
  /// 
  /// Example:
  /// ```dart
  /// final rawSocket = await RawDatagramSocket.bind(
  ///   InternetAddress.anyIPv4,
  ///   8000,
  /// );
  /// final shsp = Shsp.create(
  ///   socket: rawSocket,
  ///   remoteIp: '192.168.1.100',
  ///   remotePort: 9000,
  ///   signal: 'CLIENT_HELLO',
  /// );
  /// ```
  factory Shsp.create({
    required RawDatagramSocket socket,
    required String remoteIp,
    required int remotePort,
    String signal = '',
  }) {
    final instance = Shsp(
      socket: socket,
      remoteIp: remoteIp,
      remotePort: remotePort,
    );
    instance._signal = signal;
    return instance;
  }

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
