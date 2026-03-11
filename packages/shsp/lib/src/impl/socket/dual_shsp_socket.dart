import 'dart:io';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_instance.dart';
import '../../interfaces/socket/i_dual_shsp_socket.dart';
import '../../types/callback_types.dart';
import '../../types/peer_types.dart';
import '../../types/socket_profile.dart';
import 'shsp_socket.dart';

/// Routing adapter that manages both IPv4 and IPv6 sockets as a single unified interface.
///
/// This class implements [IDualShspSocket] and internally holds two [ShspSocket] instances:
/// - `_ipv4Socket`: IPv4 socket, always required
/// - `_ipv6Socket`: IPv6 socket, optional (may be null on systems without IPv6)
///
/// All outgoing messages are routed to the appropriate socket based on the peer's
/// address family. Message callbacks are registered on both sockets so that either
/// can receive and deliver messages to the appropriate handler.
class DualShspSocket implements IDualShspSocket {
  final ShspSocket _ipv4Socket;
  final ShspSocket? _ipv6Socket;

  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;

  DualShspSocket(this._ipv4Socket, this._ipv6Socket) {
    _onClose = CallbackOn();
    _onError = CallbackOnError();
    _onListening = CallbackOn();

    // Register callbacks on IPv4 socket to forward events
    _ipv4Socket.setListeningCallback(() {
      _onListening.call(null);
    });
    _ipv4Socket.setCloseCallback(() {
      _onClose.call(null);
    });
    _ipv4Socket.setErrorCallback((err) {
      _onError.call(err);
    });

    // Register callbacks on IPv6 socket if available
    if (_ipv6Socket != null) {
      final ipv6 = _ipv6Socket;
      ipv6.setListeningCallback(() {
        _onListening.call(null);
      });
      ipv6.setCloseCallback(() {
        _onClose.call(null);
      });
      ipv6.setErrorCallback((err) {
        _onError.call(err);
      });
    }
  }

  /// Exposes the IPv4 socket for direct access if needed
  @override
  ShspSocket get ipv4Socket => _ipv4Socket;

  /// Exposes the IPv6 socket for direct access if available
  @override
  ShspSocket? get ipv6Socket => _ipv6Socket;

  /// Get the underlying RawDatagramSocket from the IPv4 socket (for backward compatibility)
  @override
  RawDatagramSocket get socket => _ipv4Socket.socket;

  @override
  CallbackOn get onClose => _onClose;

  @override
  CallbackOnError get onError => _onError;

  @override
  CallbackOn get onListening => _onListening;

  @override
  void setListeningCallback(void Function() cb) {
    _onListening.register((_) => cb());
  }

  @override
  void setCloseCallback(void Function() cb) {
    _onClose.register((_) => cb());
  }

  @override
  void setErrorCallback(void Function(dynamic err) cb) {
    _onError.register(cb);
  }

  /// Register a message callback on both sockets.
  ///
  /// This ensures that incoming messages from either IPv4 or IPv6 are
  /// correctly delivered to the callback for the specified peer.
  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    _ipv4Socket.setMessageCallback(peer, cb);
    if (_ipv6Socket != null) {
      final ipv6 = _ipv6Socket;
      ipv6.setMessageCallback(peer, cb);
    }
  }

  /// Remove a message callback from both sockets.
  ///
  /// Returns true if the callback was found and removed from at least one socket.
  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final ipv4Removed = _ipv4Socket.removeMessageCallback(peer, cb);
    bool ipv6Removed = false;
    if (_ipv6Socket != null) {
      ipv6Removed = _ipv6Socket.removeMessageCallback(peer, cb);
    }
    return ipv4Removed || ipv6Removed;
  }

  /// Send data to a peer, routing to the appropriate socket based on address family.
  ///
  /// If the peer has an IPv6 address and IPv6 socket is available, routes to IPv6.
  /// Otherwise routes to IPv4.
  ///
  /// Returns the number of bytes written.
  @override
  int sendTo(List<int> buffer, PeerInfo peer) {
    final isIPv6 = peer.address.type == InternetAddressType.IPv6;

    if (isIPv6 && _ipv6Socket != null) {
      final ipv6 = _ipv6Socket;
      return ipv6.sendTo(buffer, peer);
    } else {
      return _ipv4Socket.sendTo(buffer, peer);
    }
  }

  /// Check if either socket is closed
  @override
  bool get isClosed => _ipv4Socket.isClosed || (_ipv6Socket?.isClosed ?? false);

  /// Close both sockets
  @override
  void close() {
    _ipv4Socket.close();
    if (_ipv6Socket != null) {
      _ipv6Socket.close();
    }
  }

  /// Serialized state of both sockets
  @override
  String serializedObject() {
    if (_ipv6Socket != null) {
      final ipv6 = _ipv6Socket;
      return 'DualShspSocket(IPv4: ${_ipv4Socket.serializedObject()}, IPv6: ${ipv6.serializedObject()})';
    } else {
      return 'DualShspSocket(IPv4: ${_ipv4Socket.serializedObject()}, IPv6: null)';
    }
  }

  /// Extract profiles from both sockets and merge them.
  ///
  /// The merged profile contains all message listeners from both IPv4 and IPv6 sockets.
  @override
  ShspSocketProfile extractProfile() {
    final ipv4Profile = _ipv4Socket.extractProfile();

    final mergedListeners = Map<String, List<OnMessageListener>>.from(
      ipv4Profile.messageListeners,
    );

    // Merge IPv6 listeners into the merged profile if available
    if (_ipv6Socket != null) {
      final ipv6Profile = _ipv6Socket.extractProfile();
      for (final entry in ipv6Profile.messageListeners.entries) {
        final key = entry.key;
        final listeners = entry.value;

        if (mergedListeners.containsKey(key)) {
          // Merge with existing listeners
          final existing = mergedListeners[key];
          if (existing != null) {
            existing.addAll(listeners);
          }
        } else {
          mergedListeners[key] = listeners;
        }
      }
    }

    return ShspSocketProfile(messageListeners: mergedListeners);
  }

  /// Apply a profile (message callbacks) to both sockets.
  ///
  /// Callbacks are registered on both IPv4 and IPv6 sockets for redundancy.
  @override
  void applyProfile(ShspSocketProfile profile) {
    _ipv4Socket.applyProfile(profile);
    if (_ipv6Socket != null) {
      _ipv6Socket.applyProfile(profile);
    }
  }

  /// Get the local address (returns IPv4 address, with IPv6 as fallback)
  @override
  InternetAddress? get localAddress {
    return _ipv4Socket.localAddress ?? _ipv6Socket?.localAddress;
  }

  /// Get the local port (returns IPv4 port, with IPv6 as fallback if IPv4 not available)
  @override
  int? get localPort {
    return _ipv4Socket.localPort ?? _ipv6Socket?.localPort;
  }

  /// Get the compression codec (from IPv4 socket)
  @override
  ICompressionCodec get compressionCodec => _ipv4Socket.compressionCodec;
  
  @override
  void destroy() {
    close();
  }
}
