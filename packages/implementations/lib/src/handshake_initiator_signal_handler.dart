import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_signal.dart';

/// Handles handshake initiation signals using a provided [HandshakeSignal].
/// Implements [IHandshakeInitiatorSignalHandler].
class HandshakeInitiatorSignalHandler implements IHandshakeInitiatorSignalHandler {
  final HandshakeSignal _signal;

  /// Creates a handler for handshake initiation using the given [HandshakeSignal].
  HandshakeInitiatorSignalHandler(this._signal);

  /// Returns the public IPv4 address info, if available.
  @override
  PeerInfo? getPublicIPv4() => _signal.publicIPv4;

  /// Returns the public IPv6 address info, if available.
  @override
  PeerInfo? getPublicIPv6() => _signal.publicIPv6;

  /// Returns the local IPv4 address info, if available.
  @override
  PeerInfo? getLocalIPv4() => _signal.localIPv4;

  /// Returns the local IPv6 address info, if available.
  @override
  PeerInfo? getLocalIPv6() => _signal.localIPv6;

  /// Returns the public key, if available.
  @override
  String? getPublicKey() => _signal.publicKey;

  /// Returns seconds until the next handshake attempt, or -1 if none planned.
  @override
  int getSecondsToNextHandshake() {
    final now = DateTime.now().toUtc();
    if (now.isAfter(_signal.endHandshakeAvailability)) return -1;
    final next = _signal.referenceTimestamp.add(
      Duration(seconds: _signal.intervalBetweenHandshakesSeconds),
    );
    return next.isAfter(now)
        ? next.difference(now).inSeconds
        : 0;
  }

  // ...existing code...
}
