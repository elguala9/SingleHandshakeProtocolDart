import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'internet_address_converter.dart';

part 'peer_types.g.dart';

@JsonSerializable()
class PeerInfo {
  @InternetAddressConverter()
  final InternetAddress address;
  final int port;

  PeerInfo({required this.address, required this.port});

  factory PeerInfo.fromJson(Map<String, dynamic> json) => _$PeerInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PeerInfoToJson(this);
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

  factory HandshakeSignal.fromJson(Map<String, dynamic> json) => _$HandshakeSignalFromJson(json);
  Map<String, dynamic> toJson() => _$HandshakeSignalToJson(this);
}
@JsonSerializable()
class SecuritySignal {
  final String? publicKey;
  final DateTime? expirationPublicKey;

  SecuritySignal({this.publicKey, this.expirationPublicKey});

  factory SecuritySignal.fromJson(Map<String, dynamic> json) => _$SecuritySignalFromJson(json);
  Map<String, dynamic> toJson() => _$SecuritySignalToJson(this);
}
typedef MessageCallback = void Function(List<int> msg, PeerInfo rinfo);
// ...existing code...

/// Peer information containing address and port
/// Uses InternetAddress for type-safe, validated IP addresses
/// 
/// Example:
/// ```dart
/// final peer = (
///   address: InternetAddress('192.168.1.1'),
///   port: 8080,
/// );
/// ```
// ...existing code...
