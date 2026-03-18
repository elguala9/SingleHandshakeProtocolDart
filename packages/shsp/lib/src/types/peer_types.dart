import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import 'internet_address_converter.dart';

@JsonSerializable()
class PeerInfo {
  PeerInfo({required this.address, required this.port});

  factory PeerInfo.fromJson(Map<String, dynamic> json) => PeerInfo(
    address:
        const InternetAddressConverter().fromJson(json['address'] as String),
    port: (json['port'] as num).toInt(),
  );

  @InternetAddressConverter()
  final InternetAddress address;
  final int port;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'address': const InternetAddressConverter().toJson(address),
    'port': port,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerInfo &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          port == other.port;

  @override
  int get hashCode => address.hashCode ^ port.hashCode;
}

@JsonSerializable()
class HandshakeSignal {
  HandshakeSignal({
    this.publicIPv6,
    this.publicIPv4,
    this.localIPv4,
    this.localIPv6,
    this.publicKey,
    this.expirationPublicKey,
    required this.referenceTimestamp,
    required this.maxHandshakeDurationSeconds,
    required this.intervalBetweenHandshakesSeconds,
    required this.endHandshakeAvailability,
  });

  factory HandshakeSignal.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields exist
      if (!json.containsKey('referenceTimestamp')) {
        throw const FormatException(
            'Missing required field: referenceTimestamp');
      }
      if (!json.containsKey('maxHandshakeDurationSeconds')) {
        throw const FormatException(
            'Missing required field: maxHandshakeDurationSeconds');
      }
      if (!json.containsKey('intervalBetweenHandshakesSeconds')) {
        throw const FormatException(
            'Missing required field: intervalBetweenHandshakesSeconds');
      }
      if (!json.containsKey('endHandshakeAvailability')) {
        throw const FormatException(
            'Missing required field: endHandshakeAvailability');
      }

      return HandshakeSignal(
        publicIPv6: json['publicIPv6'] == null
            ? null
            : PeerInfo.fromJson(json['publicIPv6'] as Map<String, dynamic>),
        publicIPv4: json['publicIPv4'] == null
            ? null
            : PeerInfo.fromJson(json['publicIPv4'] as Map<String, dynamic>),
        localIPv4: json['localIPv4'] == null
            ? null
            : PeerInfo.fromJson(json['localIPv4'] as Map<String, dynamic>),
        localIPv6: json['localIPv6'] == null
            ? null
            : PeerInfo.fromJson(json['localIPv6'] as Map<String, dynamic>),
        publicKey: json['publicKey'] as String?,
        expirationPublicKey: json['expirationPublicKey'] == null
            ? null
            : DateTime.parse(json['expirationPublicKey'] as String),
        referenceTimestamp:
            DateTime.parse(json['referenceTimestamp'] as String),
        maxHandshakeDurationSeconds:
            (json['maxHandshakeDurationSeconds'] as num).toInt(),
        intervalBetweenHandshakesSeconds:
            (json['intervalBetweenHandshakesSeconds'] as num).toInt(),
        endHandshakeAvailability:
            DateTime.parse(json['endHandshakeAvailability'] as String),
      );
    } on FormatException catch (e) {
      throw FormatException('Invalid HandshakeSignal JSON: ${e.message}');
    } on TypeError catch (e) {
      throw FormatException('Invalid HandshakeSignal JSON type: $e');
    } catch (e) {
      throw FormatException('Failed to parse HandshakeSignal JSON: $e');
    }
  }

  final PeerInfo? publicIPv6;
  final PeerInfo? publicIPv4;
  final PeerInfo? localIPv4;
  final PeerInfo? localIPv6;
  final String? publicKey;
  final DateTime? expirationPublicKey;
  final DateTime referenceTimestamp;
  final int maxHandshakeDurationSeconds;
  final int intervalBetweenHandshakesSeconds;
  final DateTime endHandshakeAvailability;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'publicIPv6': publicIPv6?.toJson(),
    'publicIPv4': publicIPv4?.toJson(),
    'localIPv4': localIPv4?.toJson(),
    'localIPv6': localIPv6?.toJson(),
    'publicKey': publicKey,
    'expirationPublicKey': expirationPublicKey?.toIso8601String(),
    'referenceTimestamp': referenceTimestamp.toIso8601String(),
    'maxHandshakeDurationSeconds': maxHandshakeDurationSeconds,
    'intervalBetweenHandshakesSeconds': intervalBetweenHandshakesSeconds,
    'endHandshakeAvailability': endHandshakeAvailability.toIso8601String(),
  };
}

@JsonSerializable()
class SecuritySignal {
  SecuritySignal({this.publicKey, this.expirationPublicKey});

  factory SecuritySignal.fromJson(Map<String, dynamic> json) => SecuritySignal(
    publicKey: json['publicKey'] as String?,
    expirationPublicKey: json['expirationPublicKey'] == null
        ? null
        : DateTime.parse(json['expirationPublicKey'] as String),
  );

  final String? publicKey;
  final DateTime? expirationPublicKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'publicKey': publicKey,
    'expirationPublicKey': expirationPublicKey?.toIso8601String(),
  };
}

typedef MessageCallback = CallbackHandler<PeerInfo, void>;
