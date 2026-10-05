import 'package:meta/meta.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../compression/gzip_codec.dart';

/// Optional helper for application code that wants to track a preferred
/// compression codec alongside its own SHSP usage.
///
/// Per SHSP spec Section 9 ("Compression is not part of SHSP"), the socket
/// itself no longer applies compression/decompression automatically to any
/// message. This mixin is kept only as an opt-in convenience for
/// applications: mix it into your own class if you want a simple place to
/// store/retrieve a codec, then call [ICompressionCodec.encode] before
/// sending and [ICompressionCodec.decode] after receiving, in your own code.
mixin ShspSocketCompressionMixin {
  late ICompressionCodec _compressionCodec;

  /// Initialize the codec kept by this mixin (default: [GZipCodec]).
  @protected
  void initCompressionCodec(ICompressionCodec? codec) {
    _compressionCodec = codec ?? GZipCodec();
  }

  /// The codec configured via [initCompressionCodec].
  ///
  /// Application-level convenience only: nothing in SHSP invokes this
  /// automatically anymore.
  ICompressionCodec get compressionCodec => _compressionCodec;
}
