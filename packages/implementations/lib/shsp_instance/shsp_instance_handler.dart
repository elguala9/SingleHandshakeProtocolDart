import 'package:shsp_implementations/shsp_instance/shsp_handshake_handler.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';



class ShspInstanceHandler implements IShspInstanceHandler {
	final Map<PeerInfo, IShspInstance> _instances = {};

	@override
	Future<IShspInstance> initiateShsp(PeerInfo remotePeer, IShspInstance instance, Opts opts) async {
    instance = await ShspHandshakeHandler.handshakeInstance(instance, const ShspHandshakeHandlerOptions());
		_instances[remotePeer] = instance;
		opts.instanceCallback?.call(instance);
		return instance;
	}

	@override
	Future<IShspInstance> getShspSafe(PeerInfo remotePeer) async {
		final instance = await getShsp(remotePeer);
		if (instance == null) {
			throw Exception('No SHSP instance found for $remotePeer');
		}
		return instance;
	}

  @override
	Future<IShspInstance?> getShsp(PeerInfo remotePeer) async {
		final instance = _instances[remotePeer];
		return instance;
	}

	@override
	void close(PeerInfo remotePeer) {
		final instance = _instances.remove(remotePeer);
		instance?.close();
	}

	@override
	void closeAll() {
		for (final instance in _instances.values) {
			instance.close();
		}
		_instances.clear();
	}
}