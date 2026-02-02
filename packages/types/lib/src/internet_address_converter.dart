import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

class InternetAddressConverter
    implements JsonConverter<InternetAddress, String> {
  const InternetAddressConverter();

  @override
  InternetAddress fromJson(String json) => InternetAddress(json);

  @override
  String toJson(InternetAddress object) => object.address;
}
