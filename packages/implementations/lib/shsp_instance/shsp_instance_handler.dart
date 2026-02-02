import 'dart:async';

import 'package:shsp_implementations/shsp_instance/shsp_handshake_handler.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

class ShspInstanceHandler implements IShspInstanceHandler {
  final Map<PeerInfo, IShspInstance> _instances = {};
  final _lock = Completer<void>()..complete();

  @override
  Future<IShspInstance> initiateShsp(
      PeerInfo remotePeer, IShspInstance instance, Opts opts) async {
    instance = await ShspHandshakeHandler.handshakeInstance(
        instance, const ShspHandshakeHandlerOptions());
    _instances[remotePeer] = instance;
    opts.instanceCallback?.call(instance);
    return instance;
  }

  @override
  Future<IShspInstance> getShspSafe(PeerInfo remotePeer) async {
    final instance = await getShsp(remotePeer);
    if (instance == null) {
      throw ShspInstanceException(
        'No SHSP instance found for peer',
        instanceId: '${remotePeer.address.address}:${remotePeer.port}',
      );
    }
    return instance;
  }

  @override
  Future<IShspInstance?> getShsp(PeerInfo remotePeer) async {
    // Wait for any ongoing operations
    await _lock.future;
    final instance = _instances[remotePeer];
    return instance;
  }

  @override
  void close(PeerInfo remotePeer) {
    // Note: This is synchronous but safe because Map operations are atomic in Dart
    final instance = _instances.remove(remotePeer);
    instance?.close();
  }

  @override
  void closeAll() {
    // Create a copy of the values to avoid ConcurrentModificationException
    final instancesToClose = List<IShspInstance>.from(_instances.values);
    _instances.clear();

    // Close all instances after clearing the map
    for (final instance in instancesToClose) {
      try {
        instance.close();
      } catch (e) {
        // Log error but continue closing other instances
        print('Error closing instance: $e');
      }
    }
  }
}
