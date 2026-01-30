import 'package:shsp_implementations/utility/message_callback_map.dart';


class MessageCallbackMapSingleton extends MessageCallbackMap {
	static MessageCallbackMapSingleton? _instance;

	factory MessageCallbackMapSingleton() {
		_instance ??= MessageCallbackMapSingleton._internal();
		return _instance!;
	}

	MessageCallbackMapSingleton._internal() : super();

	/// Distrugge il singleton (opzionale)
	static void destroy() {
		_instance = null;
	}
}
