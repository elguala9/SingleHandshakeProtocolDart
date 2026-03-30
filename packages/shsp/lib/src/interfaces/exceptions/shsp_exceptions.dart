/// Base interface for all SHSP exceptions
abstract interface class IShspException implements Exception {
  /// Human-readable error message
  String get message;
}

/// Exception thrown when a protocol-level error occurs
class ShspProtocolException implements IShspException {
  ShspProtocolException(this.message, {this.messageType, this.context});

  @override
  final String message;

  /// The message type that caused the error, if applicable
  final String? messageType;

  /// Additional context about the error
  final Map<String, dynamic>? context;

  @override
  String toString() {
    final buffer = StringBuffer('ShspProtocolException: $message');
    if (messageType != null) {
      buffer.write(' (messageType: $messageType)');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(' - context: $context');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a network-level error occurs
class ShspNetworkException implements IShspException {
  ShspNetworkException(this.message, {this.address, this.port, this.cause});

  @override
  final String message;

  /// The remote address involved in the error, if applicable
  final String? address;

  /// The remote port involved in the error, if applicable
  final int? port;

  /// The underlying cause, if available
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('ShspNetworkException: $message');
    if (address != null || port != null) {
      buffer.write(' (');
      if (address != null) buffer.write('address: $address');
      if (address != null && port != null) buffer.write(', ');
      if (port != null) buffer.write('port: $port');
      buffer.write(')');
    }
    if (cause != null) {
      buffer.write(' - caused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when input validation fails
class ShspValidationException implements IShspException {
  ShspValidationException(this.message, {this.field, this.value});

  @override
  final String message;

  /// The field that failed validation
  final String? field;

  /// The invalid value that was provided
  final Object? value;

  @override
  String toString() {
    final buffer = StringBuffer('ShspValidationException: $message');
    if (field != null) {
      buffer.write(' (field: $field');
      if (value != null) {
        buffer.write(', value: $value');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a handshake operation fails
class ShspHandshakeException implements IShspException {
  ShspHandshakeException(this.message, {this.peerInfo, this.stage});

  @override
  final String message;

  /// The peer information involved in the failed handshake
  final String? peerInfo;

  /// The stage of handshake where the error occurred
  final String? stage;

  @override
  String toString() {
    final buffer = StringBuffer('ShspHandshakeException: $message');
    if (stage != null) {
      buffer.write(' (stage: $stage');
      if (peerInfo != null) {
        buffer.write(', peer: $peerInfo');
      }
      buffer.write(')');
    } else if (peerInfo != null) {
      buffer.write(' (peer: $peerInfo)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when an instance operation fails
class ShspInstanceException implements IShspException {
  ShspInstanceException(this.message, {this.instanceId});

  @override
  final String message;

  /// The instance identifier, if applicable
  final String? instanceId;

  @override
  String toString() {
    if (instanceId != null) {
      return 'ShspInstanceException: $message (instance: $instanceId)';
    }
    return 'ShspInstanceException: $message';
  }
}

/// Exception thrown when a configuration error occurs
class ShspConfigurationException implements IShspException {
  ShspConfigurationException(this.message, {this.configKey});

  @override
  final String message;

  /// The configuration key that caused the error
  final String? configKey;

  @override
  String toString() {
    if (configKey != null) {
      return 'ShspConfigurationException: $message (config: $configKey)';
    }
    return 'ShspConfigurationException: $message';
  }
}
