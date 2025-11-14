import 'package:json_annotation/json_annotation.dart';
import 'dart:io';
import 'internet_address_converter.dart';

part 'remote_info.g.dart';

/// Remote information containing address and port
@JsonSerializable()
class RemoteInfo {
  @InternetAddressConverter()
  final InternetAddress address;
  final int port;

  RemoteInfo({required this.address, required this.port});

  factory RemoteInfo.fromJson(Map<String, dynamic> json) => _$RemoteInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteInfoToJson(this);
}