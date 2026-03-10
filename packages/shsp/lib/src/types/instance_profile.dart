import 'package:callback_handler/callback_handler.dart';
import 'peer_types.dart';

typedef OnVoidListener = CallbackWithReturn<void, void>;
typedef OnPeerListener = CallbackWithReturn<PeerInfo, void>;

/// Immutable snapshot of a ShspInstance's listener registrations and configuration.
///
/// This profile can be extracted from an existing ShspInstance and applied to a new
/// instance to avoid re-registering callbacks when reconnecting over a new socket.
class ShspInstanceProfile {
  final int keepAliveSeconds;
  final List<OnVoidListener> onHandshakeListeners;
  final List<OnVoidListener> onOpenListeners;
  final List<OnVoidListener> onClosingListeners;
  final List<OnVoidListener> onCloseListeners;
  final List<OnPeerListener> onMessageListeners;

  const ShspInstanceProfile({
    this.keepAliveSeconds = 30,
    this.onHandshakeListeners = const [],
    this.onOpenListeners = const [],
    this.onClosingListeners = const [],
    this.onCloseListeners = const [],
    this.onMessageListeners = const [],
  });
}
