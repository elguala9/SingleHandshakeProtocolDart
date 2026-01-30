import 'dart:io';

import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/utility/message_callback_map_singleton.dart';
import 'package:shsp_implementations/utility/shsp_socket_info_singleton.dart';


/// SHSP Socket implementation wrapping RawDatagramSocket 
class ShspSocketSingleton extends ShspSocket {
	static ShspSocketSingleton? _instance;

	ShspSocketSingleton._internal(super.socket, super._messageCallbacks) : super.internal();

	/// Factory async per creare o restituire il singleton
	static Future<ShspSocketSingleton> bind({ShspSocketInfoSingleton? info, MessageCallbackMapSingleton? callbacks}) async {
    if (_instance != null) return _instance!;
    info ??= ShspSocketInfoSingleton();
    callbacks ??= MessageCallbackMapSingleton();
    final rawSocket = await RawDatagramSocket.bind(info.address, info.port);
		_instance = ShspSocketSingleton._internal(rawSocket, callbacks);
		return _instance!;
	}

	/// Restituisce l'istanza se già creata, altrimenti null
	static ShspSocketSingleton? get instance => _instance;

	/// Distrugge il singleton e chiude la socket
	static void destroy() {
		_instance?.close();
		_instance = null;
	}
}
