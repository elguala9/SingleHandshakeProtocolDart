import 'dart:io';

import 'package:shsp/shsp.dart';
import 'registry_shsp.dart';

/// Initializes the socket registry with provided IPv4 and IPv6 socket instances
void initializeSocketRegistry({
  required IShspSocket ipv4Socket,
  required IShspSocket ipv6Socket,
}) {
  final registry = RegistrySingletonShspSocket.instance;
  registry.register(SocketType.ipv4, ipv4Socket);
  registry.register(SocketType.ipv6, ipv6Socket);
}

/// Creates and initializes the socket registry with new IPv4 and IPv6 sockets
Future<void> initializeSocketRegistryWithNewSockets({
  InternetAddress? ipv4Address,
  int ipv4Port = 0,
  InternetAddress? ipv6Address,
  int ipv6Port = 0,
}) async {
  final registry = RegistrySingletonShspSocket.instance;

  final ipv4Socket = await ShspSocket.bind(
    ipv4Address ?? InternetAddress.anyIPv4,
    ipv4Port,
  );
  final ipv6Socket = await ShspSocket.bind(
    ipv6Address ?? InternetAddress.anyIPv6,
    ipv6Port,
  );

  registry.register(SocketType.ipv4, ipv4Socket);
  registry.register(SocketType.ipv6, ipv6Socket);
}
