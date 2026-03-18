import 'package:meta/meta.dart';
import '../../../interfaces/i_shsp_instance.dart' show CallbackOn;

const int handshakePrefix = 0x01;
const int closingPrefix = 0x02;
const int closedPrefix = 0x03;

/// Mixin for managing handshake and connection closing logic
mixin ShspInstanceHandshakeMixin {
  /// Protected getters/setters for state (implemented by the class using this mixin)
  bool get handshakeState;
  set handshakeState(bool value);

  bool get closingState;
  set closingState(bool value);

  bool get openState;
  set openState(bool value);

  late CallbackOn onHandshake;
  late CallbackOn onClosing;
  late CallbackOn onClose;

  /// Get handshake state
  bool get handshake => handshakeState;

  /// Get closing state
  bool get closing => closingState;

  /// Get open/connected state
  bool get open => openState;

  /// Send a handshake message
  void sendHandshake() {
    final List<int> msg = [handshakePrefix];
    if (handshakeState) {
      // if i got the handshake i add a 0x01 to inform the other peer
      msg.add(handshakePrefix);
    }
    sendMessageInternal(msg);
  }

  /// Send a closing signal
  void sendClosing() {
    sendMessageInternal([closingPrefix]);
    closingState = true;
  }

  /// Send a closed signal
  void sendClosed() {
    sendMessageUnchecked([closedPrefix]);
    closingState = false;
    openState = false;
  }

  /// Check if message is a handshake (0x01)
  @protected
  bool isHandshake(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == handshakePrefix) {
      handshakeState = true; // i got the handshake of the other peer
      onHandshake.call(null);
      // if [0x01, 0x01] then the other peer got my handshake
      if (msg.length > 1 && msg[1] == handshakePrefix) {
        openState = true;
        // Note: onOpen callback is called from the main instance
      }
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x02)
  @protected
  bool isClosing(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closingPrefix) {
      closingState = true;
      onClosing.call(null);
      return true;
    }
    return false;
  }

  /// Check if message is a closed signal (0x03)
  @protected
  bool isClosed(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closedPrefix) {
      closingState = false;
      openState = false;
      onClose.call(null);
      return true;
    }
    return false;
  }

  /// Send message (internal, subclass must implement)
  @protected
  void sendMessageInternal(List<int> message);

  /// Send message without checks (internal, subclass must implement)
  @protected
  void sendMessageUnchecked(List<int> message);
}
