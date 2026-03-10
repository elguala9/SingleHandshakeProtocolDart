import 'package:callback_handler/callback_handler.dart';
import 'callback_types.dart';
import 'remote_info.dart';

typedef OnMessageListener = CallbackWithReturn<MessageRecord, void>;

/// Immutable snapshot of a ShspSocket's message callback registrations.
///
/// This profile captures the message callbacks registered for each remote peer
/// and can be applied to a new socket instance to avoid re-registering callbacks
/// when the socket changes (e.g., UDP reconnection with new local port).
class ShspSocketProfile {
  /// Map of peer keys (formatted as "address:port") to their message listeners
  final Map<String, List<OnMessageListener>> messageListeners;

  const ShspSocketProfile({
    this.messageListeners = const {},
  });
}
