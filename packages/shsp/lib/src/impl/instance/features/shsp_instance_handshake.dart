import 'package:meta/meta.dart';
import '../../../../shsp.dart';

const int handshakePrefix = 0x01;
const int handshakeAckPrefix = 0x02;
const int closingPrefix = 0x03;
const int closedPrefix = 0x04;

/// Declarative protocol version carried in the handshake probe body.
/// Pinned to 0x00 for this revision of the specification (Section 13).
const int shspVersion = 0x00;

/// Mixin for managing the explicit connection state machine (Section 5), the
/// handshake procedure (Section 6) and connection closing (Section 8).
mixin ShspInstanceHandshakeMixin {
  /// Protected getter/setter for the explicit connection state (implemented
  /// by the class using this mixin). Source of truth for [handshake],
  /// [closing] and [open].
  ShspConnectionState get connectionState;
  set connectionState(ShspConnectionState value);

  late CallbackOn onHandshake;
  late CallbackOn onClosing;
  late CallbackOn onClose;

  bool _peerProbeObserved = false;

  /// Get handshake state: true from HANDSHAKING onward (i.e. as soon as the
  /// session has left CREATED).
  bool get handshake => connectionState != ShspConnectionState.created;

  /// Get closing state: true only while in CLOSING.
  bool get closing => connectionState == ShspConnectionState.closing;

  /// Get open/connected state: true from the moment the handshake is
  /// confirmed until the session reaches CLOSED (i.e. also true while
  /// CLOSING, matching the pre-existing observable API).
  bool get open =>
      connectionState == ShspConnectionState.open ||
      connectionState == ShspConnectionState.closing;

  /// Send a handshake probe (0x01), carrying the mandatory VERSION byte
  /// (Section 4, Section 6, Section 13). Exits CREATED into HANDSHAKING
  /// (Section 5). A CLOSED session MUST NOT be reused (Section 5): the call
  /// is a no-op there; reconnect by creating a new instance (e.g.
  /// `ShspInstance.withProfile`). Left untouched once past HANDSHAKING
  /// (OPEN/CLOSING) so a redundant call never downgrades an active session.
  void sendHandshake() {
    if (connectionState == ShspConnectionState.closed) return;
    if (connectionState == ShspConnectionState.created) {
      connectionState = ShspConnectionState.handshaking;
    }
    sendMessageInternal([handshakePrefix, shspVersion]);
  }

  /// Send a handshake acknowledgment (0x02), a dedicated 1-byte message with no body
  void sendHandshakeAck() {
    sendMessageInternal([handshakeAckPrefix]);
  }

  /// Send a closing signal (graceful close request, Section 8). Transitions
  /// the session into CLOSING (Section 5). Only meaningful while OPEN; a
  /// no-op in any other state.
  void sendClosing() {
    if (connectionState != ShspConnectionState.open) return;
    sendMessageInternal([closingPrefix]);
    connectionState = ShspConnectionState.closing;
  }

  /// Send a closed signal. Transitions the session into CLOSED (Section 5).
  void sendClosed() {
    sendMessageUnchecked([closedPrefix]);
    connectionState = ShspConnectionState.closed;
  }

  /// Check if message is a handshake probe (0x01).
  ///
  /// The VERSION byte is mandatory (Section 4, Section 6, Section 13): a
  /// handshake datagram with no body (1 byte total) is malformed and is
  /// discarded (Section 10), never treated as an
  /// implicit VERSION = 0x00.
  @protected
  bool isHandshake(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == handshakePrefix) {
      if (msg.length < 2) {
        // Malformed handshake, message discarded (Section 10)
        return false;
      }
      // The peer-declared VERSION byte (msg[1]) is purely declarative
      // (Section 6 step 9, Section 12) and is not used for any security
      // or negotiation decision.
      // Any bytes following VERSION are ignored (Section 4, extensibility).
      // Received a valid handshake probe from the other peer: exits CREATED
      // into HANDSHAKING (Section 5). Left untouched once past HANDSHAKING
      // so a redundant/duplicate probe never downgrades an active session.
      // CLOSED sessions never get here (discarded by the caller).
      if (connectionState == ShspConnectionState.created) {
        connectionState = ShspConnectionState.handshaking;
      }
      // Notify only on the first probe observed from the counterpart, not on
      // every duplicate/retransmitted probe.
      if (!_peerProbeObserved) {
        _peerProbeObserved = true;
        onHandshake.call(null);
      }
      return true;
    }
    return false;
  }

  /// Check if message is a handshake acknowledgment (0x02)
  @protected
  bool isHandshakeAck(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == handshakeAckPrefix) {
      // An ack only confirms the handshake while HANDSHAKING; a stray ack in
      // CLOSING/CLOSED must not revive the session (Section 5).
      if (connectionState == ShspConnectionState.handshaking) {
        connectionState = ShspConnectionState.open;
      }
      // Note: onOpen callback is called from the main instance
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x03). State transitions and the
  /// mandatory `Closed` reply (Section 8) are handled by the instance.
  @protected
  bool isClosingMessage(List<int> msg) =>
      msg.isNotEmpty && msg[0] == closingPrefix;

  /// Check if message is a closed signal (0x04). The CLOSED transition and
  /// the [onClose] notification are handled by the instance.
  @protected
  bool isClosedMessage(List<int> msg) =>
      msg.isNotEmpty && msg[0] == closedPrefix;

  /// Send message (internal, subclass must implement)
  @protected
  void sendMessageInternal(List<int> message);

  /// Send message without checks (internal, subclass must implement)
  @protected
  void sendMessageUnchecked(List<int> message);
}
