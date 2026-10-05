import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'internet_address_converter.dart';

@JsonSerializable()
class PeerInfo {
  PeerInfo({required this.address, required this.port});

  factory PeerInfo.fromJson(Map<String, dynamic> json) => PeerInfo(
    address: const InternetAddressConverter().fromJson(
      json['address'] as String,
    ),
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
