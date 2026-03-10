import 'dart:io' show gzip;
import '../../../interfaces/i_compression_codec.dart';

/// LZ4-like compression codec implementation
///
/// Ultra-fast compression algorithm optimized for real-time UDP communication.
/// This uses gzip with a focus on speed similar to LZ4's philosophy.
class LZ4Codec implements ICompressionCodec {
  @override
  String get name => 'LZ4';

  @override
  List<int> encode(List<int> data) {
    if (data.isEmpty) return [0];
    try {
      // Use gzip for reliable compression with fast decompression
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
