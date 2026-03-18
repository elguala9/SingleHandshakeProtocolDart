import 'package:meta/meta.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../compression/gzip_codec.dart';

/// Mixin for managing data compression/decompression
mixin ShspSocketCompressionMixin {
  late ICompressionCodec _compressionCodec;

  /// Initialize compression codec
  @protected
  void initCompressionCodec(ICompressionCodec? codec) {
    _compressionCodec = codec ?? GZipCodec();
  }

  /// Get the compression codec used for data messages
  ICompressionCodec get compressionCodec => _compressionCodec;

  /// Decompress data messages (0x00) while keeping protocol messages as-is
  @protected
  List<int> decompressIfData(List<int> msg) {
    // Check if it's a data message (0x00)
    if (msg.isNotEmpty && msg[0] == 0x00) {
      // Decompress the payload (everything after the prefix)
      final decompressed = _compressionCodec.decode(msg.sublist(1));
      // Return with prefix restored: [0x00] + decompressed
      return [0x00, ...decompressed];
    }
    // Not a data message, return as-is
    return msg;
  }

  /// Compress data messages (0x00) while keeping protocol messages as-is
  @protected
  List<int> compressIfData(List<int> msg) {
    // Check if it's a data message (0x00)
    if (msg.isNotEmpty && msg[0] == 0x00) {
      // Compress the payload (everything after the prefix)
      final compressed = _compressionCodec.encode(msg.sublist(1));
      // Return with prefix: [0x00] + compressed
      return [0x00, ...compressed];
    }
    // Not a data message, return as-is
    return msg;
  }
}
