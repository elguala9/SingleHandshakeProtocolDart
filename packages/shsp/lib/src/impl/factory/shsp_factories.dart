import 'dart:io';

import '../../interfaces/i_shsp_socket.dart';
import '../../types/instance_profile.dart';
import '../../types/peer_types.dart';
import '../socket/core/shsp_socket.dart';
import '../peer/shsp_peer.dart';
import '../instance/core/shsp_instance.dart';
import '../utility/message_callback_map.dart';
import '../utility/utility_factories.dart';
import './factory_inputs.dart';
// imports for factories are exported by the package barrel; keep minimal imports here

/// Static factory for creating ShspSocket instances
/// See IShspSocketFactory for the interface contract
class ShspSocketFactory {
  static ShspSocket create(
    RawDatagramSocket socket,
    MessageCallbackMap messageCallbacks,
  ) => ShspSocket.internal(socket, messageCallbacks);

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

/// Static factory for creating ShspPeer instances
/// See IShspPeerFactory for the interface contract
class ShspPeerFactory {
  static ShspPeer create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
  }) => ShspPeer(remotePeer: remotePeer, socket: socket);

  /// Create a ShspPeer from a RemoteInfo object and a raw socket.
  /// This will build required dependencies (MessageCallbackMap and ShspSocket) internally.
  static ShspPeer createFromRemoteInfo({
    required PeerInfo remotePeer,
    required RawDatagramSocket rawSocket,
  }) {
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(rawSocket, messageCallbacks);
    return ShspPeer(remotePeer: remotePeer, socket: shspSocket);
  }

  /// Create a `ShspPeer` from a `ShspPeerConfig` object.
  /// If `config.socket` is provided it will be used; otherwise `config.rawSocket` will be used to build a socket.
  static ShspPeer createFromConfig(ShspPeerInput config) {
    if (config.socket != null) {
      return ShspPeer(remotePeer: config.remotePeer, socket: config.socket!);
    }
    if (config.rawSocket != null) {
      return createFromRemoteInfo(
        remotePeer: config.remotePeer,
        rawSocket: config.rawSocket!,
      );
    }
    // Fallback: create a RawDatagramSocket bound to any IPv4 port
    // Note: binding is synchronous here; callers can prefer to pass a rawSocket.
    final raw =
        RawDatagramSocket.bind(InternetAddress.anyIPv4, 0) as RawDatagramSocket;
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(raw, messageCallbacks);
    return ShspPeer(remotePeer: config.remotePeer, socket: shspSocket);
  }
}

/// Static factory for creating ShspInstance instances
/// See IShspInstanceFactory for the interface contract
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
    if (config.socket != null) {
      return ShspInstance(
        remotePeer: config.remotePeer,
        socket: config.socket!,
        keepAliveSeconds: config.keepAliveSeconds,
      );
    }
    if (config.rawSocket != null) {
      return createFromSocket(
        remotePeer: config.remotePeer,
        rawSocket: config.rawSocket!,
        keepAliveSeconds: config.keepAliveSeconds,
      );
    }
    final raw =
        RawDatagramSocket.bind(InternetAddress.anyIPv4, 0) as RawDatagramSocket;
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(raw, messageCallbacks);
    return ShspInstance(
      remotePeer: config.remotePeer,
      socket: shspSocket,
      keepAliveSeconds: config.keepAliveSeconds,
    );
  }

  /// Create a `ShspInstance` from an existing profile extracted from another instance.
  ///
  /// This is useful for reconnecting over a new socket (e.g., UDP reconnection)
  /// while preserving all registered callbacks and configuration.
  /// The new instance will still perform a full handshake.
  static ShspInstance createWithProfile({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    required ShspInstanceProfile profile,
  }) => ShspInstance.withProfile(
    remotePeer: remotePeer,
    socket: socket,
    profile: profile,
  );
}

// Inputs are defined in factory_inputs.dart
