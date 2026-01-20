import 'dart:io';

import 'package:shsp_implementations/single_hand_shake_protocol_monorepo.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
// imports for factories are exported by the package barrel; keep minimal imports here



class ShspSocketFactory {
  static ShspSocket create(RawDatagramSocket socket, MessageCallbackMap messageCallbacks) =>
      ShspSocket.internal(socket, messageCallbacks);

  /// Create a ShspSocket providing only a RawDatagramSocket.
  /// This will create a default MessageCallbackMap internally.
  static ShspSocket createFromSocket(RawDatagramSocket socket) {
    final messageCallbacks = MessageCallbackMapFactory.create();
    return ShspSocket.internal(socket, messageCallbacks);
  }

  /// Create using a configuration object.
  static ShspSocket createFromConfig(ShspSocketInput config) {
    final mc = config.messageCallbacks ?? MessageCallbackMapFactory.create();
    return ShspSocket.internal(config.socket, mc);
  }
}


class ShspPeerFactory {
  static ShspPeer create({required PeerInfo remotePeer, required IShspSocket socket}) =>
      ShspPeer(remotePeer: remotePeer, socket: socket);

  /// Create a ShspPeer from a RemoteInfo object and a raw socket.
  /// This will build required dependencies (MessageCallbackMap and ShspSocket) internally.
  static ShspPeer createFromRemoteInfo({required PeerInfo remotePeer, required RawDatagramSocket rawSocket}) {
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(rawSocket, messageCallbacks);
    return ShspPeer(remotePeer: remotePeer, socket: shspSocket);
  }

  /// Create a `ShspPeer` from a `ShspPeerConfig` object.
  /// If `config.socket` is provided it will be used; otherwise `config.rawSocket` will be used to build a socket.
  static ShspPeer createFromConfig(ShspPeerInput config) {
    if (config.socket != null) return ShspPeer(remotePeer: config.remotePeer, socket: config.socket!);
    if (config.rawSocket != null) return createFromRemoteInfo(remotePeer: config.remotePeer, rawSocket: config.rawSocket!);
    // Fallback: create a RawDatagramSocket bound to any IPv4 port
    // Note: binding is synchronous here; callers can prefer to pass a rawSocket.
    final raw = RawDatagramSocket.bind(InternetAddress.anyIPv4, 0) as RawDatagramSocket;
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(raw, messageCallbacks);
    return ShspPeer(remotePeer: config.remotePeer, socket: shspSocket);
  }
}


class ShspInstanceFactory {
  static ShspInstance create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    int keepAliveSeconds = 30,
  }) => ShspInstance(
    remotePeer: remotePeer,
    socket: socket,
    keepAliveSeconds: keepAliveSeconds,
  );

  /// Create a ShspInstance from PeerInfo and a RawDatagramSocket, building dependencies.
  static ShspInstance createFromSocket({
    required PeerInfo remotePeer,
    required RawDatagramSocket rawSocket,
    int keepAliveSeconds = 30,
  }) {
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(rawSocket, messageCallbacks);
    return ShspInstance(
      remotePeer: remotePeer,
      socket: shspSocket,
      keepAliveSeconds: keepAliveSeconds,
    );
  }

  /// Create a `ShspInstance` from a `ShspInstanceConfig` object.
  static ShspInstance createFromConfig(ShspInstanceInput config) {
    if (config.socket != null) return ShspInstance(remotePeer: config.remotePeer, socket: config.socket!, keepAliveSeconds: config.keepAliveSeconds);
    if (config.rawSocket != null) return createFromSocket(remotePeer: config.remotePeer, rawSocket: config.rawSocket!, keepAliveSeconds: config.keepAliveSeconds);
    final raw = RawDatagramSocket.bind(InternetAddress.anyIPv4, 0) as RawDatagramSocket;
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(raw, messageCallbacks);
    return ShspInstance(remotePeer: config.remotePeer, socket: shspSocket, keepAliveSeconds: config.keepAliveSeconds);
  }
}


class ShspFactory {
  static Shsp create({
    required RawDatagramSocket socket,
    required String remoteIp,
    required int remotePort
  }) => Shsp(
    socket: socket,
    remoteIp: remoteIp,
    remotePort: remotePort,
  );

  /// Create a `Shsp` from a `ShspConfig` object.
  static Shsp createFromConfig(ShspInput config) {
    final ip = config.peerInfo?.address.address ?? config.remoteIp;
    final port = config.peerInfo?.port ?? config.remotePort;
    if (ip == null || port == null) {
      throw ArgumentError('Either peerInfo or remoteIp and remotePort must be provided in ShspInput');
    }
    return Shsp(socket: config.socket, remoteIp: ip, remotePort: port);
  }
}

// Inputs are defined in factory_inputs.dart
