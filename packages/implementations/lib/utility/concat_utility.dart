import 'dart:typed_data';
import 'dart:convert';

/// Utility functions for concatenating data
class ConcatUtility {
  /// Concatenate multiple strings
  static String concatStrings(List<String> strings) {
    return strings.join('');
  }

  /// Concatenate multiple Uint8List (byte arrays)
  static Uint8List concatBytes(List<Uint8List> arrays) {
    if (arrays.isEmpty) return Uint8List(0);
    
    // Calculate total length
    int totalLength = arrays.fold(0, (sum, array) => sum + array.length);
    
    // Create result array
    final result = Uint8List(totalLength);
    
    // Copy all arrays into result
    int offset = 0;
    for (final array in arrays) {
      result.setRange(offset, offset + array.length, array);
      offset += array.length;
    }
    
    return result;
  }

  /// Concatenate multiple List<int> (generic int lists)
  static List<int> concatIntLists(List<List<int>> lists) {
    if (lists.isEmpty) return [];
    
    final result = <int>[];
    for (final list in lists) {
      result.addAll(list);
    }
    
    return result;
  }

  /// Convert a String to Uint8List
  static Uint8List stringToBytes(String str, {Encoding encoding = utf8}) {
    return Uint8List.fromList(encoding.encode(str));
  }

  /// Convert a Uint8List to String
  static String bytesToString(Uint8List bytes, {Encoding encoding = utf8}) {
    return encoding.decode(bytes);
  }

  /// Concatenate mixed types (strings and byte arrays)
  /// All strings are converted to bytes using UTF-8 encoding
  static Uint8List concatMixed(List<dynamic> items) {
    final byteArrays = <Uint8List>[];
    
    for (final item in items) {
      if (item is String) {
        byteArrays.add(stringToBytes(item));
      } else if (item is Uint8List) {
        byteArrays.add(item);
      } else if (item is List<int>) {
        byteArrays.add(Uint8List.fromList(item));
      } else {
        throw ArgumentError('Unsupported type: ${item.runtimeType}. '
            'Only String, Uint8List, and List<int> are supported.');
      }
    }
    
    return concatBytes(byteArrays);
  }
}
