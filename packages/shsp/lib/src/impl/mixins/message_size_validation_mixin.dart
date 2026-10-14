import '../../interfaces/exceptions/shsp_exceptions.dart';

mixin MessageSizeValidationMixin {
  /// Maximum UDP payload over IPv4 (Section 3).
  static const int maxMessageSize = 65507;

  /// Maximum UDP payload over IPv6, jumbograms excluded (Section 3).
  static const int maxMessageSizeIPv6 = 65527;

  void validateNotClosed(bool closed, String address, int port) {
    if (closed) {
      throw ShspNetworkException(
        'Cannot send message: peer is closed',
        address: address,
        port: port,
      );
    }
  }

  void validateNotEmpty(List<int> message) {
    if (message.isEmpty) {
      throw ShspValidationException(
        'Message cannot be empty',
        field: 'message',
        value: message,
      );
    }
  }

  void validateMaxSize(List<int> message, {bool ipv6 = false}) {
    final limit = ipv6 ? maxMessageSizeIPv6 : maxMessageSize;
    if (message.length > limit) {
      throw ShspValidationException(
        'Message size ${message.length} exceeds maximum $limit bytes',
        field: 'message.length',
        value: message.length,
      );
    }
  }

  void validateOutgoingMessage(
    List<int> message,
    bool closed,
    String address,
    int port, {
    bool ipv6 = false,
  }) {
    validateNotClosed(closed, address, port);
    validateNotEmpty(message);
    validateMaxSize(message, ipv6: ipv6);
  }
}
