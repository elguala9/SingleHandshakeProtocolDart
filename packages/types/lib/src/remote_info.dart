import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'internet_address_converter.dart';

/// Remote information containing address and port
@JsonSerializable()
class RemoteInfo {
  @InternetAddressConverter()
  final InternetAddress address;
  final int port;

  RemoteInfo({required this.address, required this.port});

  factory RemoteInfo.fromJson(Map<String, dynamic> json) {
    return RemoteInfo(
      address:
          const InternetAddressConverter().fromJson(json['address'] as String),
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
