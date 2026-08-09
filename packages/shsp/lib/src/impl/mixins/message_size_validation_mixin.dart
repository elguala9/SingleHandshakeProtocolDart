import '../../interfaces/exceptions/shsp_exceptions.dart';

mixin MessageSizeValidationMixin {
  static const int maxMessageSize = 65507;

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

  void validateMaxSize(List<int> message) {
    if (message.length > maxMessageSize) {
      throw ShspValidationException(
        'Message size ${message.length} exceeds maximum $maxMessageSize bytes',
        field: 'message.length',
        value: message.length,
      );
    }
  }

  void validateOutgoingMessage(List<int> message, bool closed, String address, int port) {
    validateNotClosed(closed, address, port);
    validateNotEmpty(message);
    validateMaxSize(message);
  }
}
