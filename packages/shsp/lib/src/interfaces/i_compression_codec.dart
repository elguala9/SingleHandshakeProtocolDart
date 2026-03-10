/// Compression codec interface for SHSP data messages
abstract class ICompressionCodec {
  /// Compress data
  ///
  /// Parameters:
  ///   - [data]: Raw data to compress
  ///
  /// Returns: Compressed data
  List<int> encode(List<int> data);

  /// Decompress data
  ///
  /// Parameters:
  ///   - [data]: Compressed data to decompress
  ///
  /// Returns: Decompressed data
  List<int> decode(List<int> data);

  /// Human-readable name of the compression algorithm
  String get name;
}
