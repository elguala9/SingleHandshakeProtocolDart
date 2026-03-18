import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import '../../../../shsp.dart';


/// Simple singleton for managing a global DualShspSocket instance
///
/// This is a minimal, straightforward singleton implementation for
/// managing a single DualShspSocket globally. Perfect for simple use cases.
///
/// Example:
/// ```dart
/// final socket = await DualShspSocket.create(
///   ipv4Address: InternetAddress.anyIPv4,
///   ipv4Port: 8080,
/// );
/// SimpleDualSocketSingleton.instance.setInstance(socket);
///
/// // Use it anywhere
/// final socket = SimpleDualSocketSingleton.instance.getInstance();
/// ```
class SimpleDualSocketSingleton implements ISimpleDualSocketSingleton {
  factory SimpleDualSocketSingleton() => _instance;

  SimpleDualSocketSingleton._internal();

  static final SimpleDualSocketSingleton _instance =
      SimpleDualSocketSingleton._internal();

  static SimpleDualSocketSingleton get instance => _instance;

  @protected
  late IDualShspSocket? dualSocket;

  IDualShspSocket? getInstance() => dualSocket;

  void setInstance(IDualShspSocket socket) {
    dualSocket?.close();
    dualSocket = socket;
  }

  bool hasInstance() => dualSocket != null;

  void clear() {
    dualSocket?.close();
    dualSocket = null;
  }


}
