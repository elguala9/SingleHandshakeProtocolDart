import 'package:shsp/src/impl/shsp_base/shsp_socket.dart';
import 'package:shsp/shsp.dart';

/// Extension to expose protected onMessage method for testing purposes
extension TestableShspSocketExt on ShspSocket {
  /// Simulate receiving a message (for testing purposes only)
  /// Uses the protected onMessage method via dynamic to bypass access restrictions
  void testOnMessage(List<int> msg, RemoteInfo rinfo) {
    // Access the protected method using dynamic dispatch
    (this as dynamic).onMessage(msg, rinfo);
  }
}
