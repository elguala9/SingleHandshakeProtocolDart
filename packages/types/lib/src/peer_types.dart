import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'internet_address_converter.dart';

@JsonSerializable()
class PeerInfo {
  @InternetAddressConverter()
  final InternetAddress address;
  final int port;

  PeerInfo({required this.address, required this.port});

  factory PeerInfo.fromJson(Map<String, dynamic> json) {
    return PeerInfo(
      address: const InternetAddressConverter().fromJson(json['address'] as String),
      port: (json['port'] as num).toInt(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'address': const InternetAddressConverter().toJson(address),
      'port': port,
    };
  }
}

@JsonSerializable()
class HandshakeSignal {
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
      referenceTimestamp: DateTime.parse(json['referenceTimestamp'] as String),
      maxHandshakeDurationSeconds: (json['maxHandshakeDurationSeconds'] as num).toInt(),
      intervalBetweenHandshakesSeconds: (json['intervalBetweenHandshakesSeconds'] as num).toInt(),
      endHandshakeAvailability: DateTime.parse(json['endHandshakeAvailability'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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
}

@JsonSerializable()
class SecuritySignal {
  final String? publicKey;
  final DateTime? expirationPublicKey;

  SecuritySignal({this.publicKey, this.expirationPublicKey});

  factory SecuritySignal.fromJson(Map<String, dynamic> json) {
    return SecuritySignal(
      publicKey: json['publicKey'] as String?,
      expirationPublicKey: json['expirationPublicKey'] == null
          ? null
          : DateTime.parse(json['expirationPublicKey'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'publicKey': publicKey,
      'expirationPublicKey': expirationPublicKey?.toIso8601String(),
    };
  }
}

typedef MessageCallback = void Function(List<int> msg, PeerInfo rinfo);
