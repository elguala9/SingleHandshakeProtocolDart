import 'dart:io';
import '../i_shsp_socket.dart';

/// Socket interface for dual IPv4/IPv6 support
/// Routes messages to the appropriate socket based on peer address family
abstract interface class IDualShspSocket implements IShspSocket {
  /// Get the underlying IPv4 socket
  IShspSocket? get ipv4Socket;

  /// Get the underlying IPv6 socket if available
  IShspSocket? get ipv6Socket;

  /// Get the underlying RawDatagramSocket (typically from IPv4)
  @override
  RawDatagramSocket get socket;
}