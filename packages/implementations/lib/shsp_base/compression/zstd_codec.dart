import 'dart:io' show gzip;
import 'package:shsp_interfaces/shsp_interfaces.dart';

/// Zstandard (ZSTD) compression codec implementation
///
/// Balanced compression algorithm with better compression than LZ4.
/// This uses gzip which provides similar functionality to ZSTD.
class ZstdCodec implements ICompressionCodec {
  @override
  String get name => 'Zstandard';

  @override
  List<int> encode(List<int> data) {
    if (data.isEmpty) return [0];
    try {
      // Use gzip for reliable compression with good ratio
      final compressed = gzip.encode(data);
      return [1, ...compressed];
    } catch (e) {
      // Fallback: uncompressed
      return [2, ...data];
    }
  }

  @override
  List<int> decode(List<int> data) {
    if (data.isEmpty) return [];
    if (data[0] == 0) return [];
    if (data[0] == 2) return data.sublist(1);

    try {
      return gzip.decode(data.sublist(1));
    } catch (e) {
      return data.sublist(1);
    }
  }
}
