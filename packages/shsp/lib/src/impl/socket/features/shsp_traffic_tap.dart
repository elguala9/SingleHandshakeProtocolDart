import 'dart:io';

/// Observes every datagram a [ShspSocket] receives or sends.
///
/// Diagnostic hook only: it sees the real remote endpoint of each datagram,
/// which the per-peer callbacks hide. [matched] is false when no message
/// callback was registered for the sender, so the datagram was dropped.
abstract interface class IShspTrafficTap {
  /// Called for each received datagram.
  void onReceive(InternetAddress address, int port, int length, bool matched);

  /// Called for each send; [result] is the byte count the socket accepted
  /// (0 means rejected or queued).
  void onSend(InternetAddress address, int port, int length, int result);
}

/// Process-wide [IShspTrafficTap]; null (the default) disables tapping.
class ShspTrafficTap {
  ShspTrafficTap._();

  /// The installed tap, or null when tapping is off.
  static IShspTrafficTap? instance;
}
