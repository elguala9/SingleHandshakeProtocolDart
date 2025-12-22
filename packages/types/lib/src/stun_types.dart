import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';

part 'stun_types.g.dart';

/// STUN response containing public IP information
@JsonSerializable()
class StunResponse {
  /// Public IP address (e.g., "203.0.113.42")
  final String publicIp;

  /// Public port number (e.g., 54723)
  final int publicPort;

  /// Transaction ID from the STUN request (12 bytes)
  @JsonKey(fromJson: _listToUint8List, toJson: _uint8ListToList)
  final Uint8List transactionId;

  /// Raw STUN packet received (binary)
  @JsonKey(fromJson: _listToUint8List, toJson: _uint8ListToList)
  final Uint8List raw;

  /// Optional additional STUN attributes
  final Map<String, dynamic>? attrs;

  StunResponse({
    required this.publicIp,
    required this.publicPort,
    required this.transactionId,
    required this.raw,
    this.attrs,
  });

  factory StunResponse.fromJson(Map<String, dynamic> json) => _$StunResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StunResponseToJson(this);

  static Uint8List _listToUint8List(List<dynamic> list) {
    return Uint8List.fromList(list.cast<int>());
  }

  static List<int> _uint8ListToList(Uint8List data) {
    return data.toList();
  }
}

/// Local network information
@JsonSerializable()
class LocalInfo {
  /// Local IP address (e.g., "192.168.1.2")
  final String localIp;

  /// Local port number (e.g., 12345)
  final int localPort;

  LocalInfo({
    required this.localIp,
    required this.localPort,
  });

  factory LocalInfo.fromJson(Map<String, dynamic> json) => _$LocalInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LocalInfoToJson(this);
}
