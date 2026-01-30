import 'keep_alive_timer.dart';
import 'message_callback_map.dart';
import 'callback_map.dart';
import 'address_utility.dart';

import '../factory/factory_inputs.dart';

class KeepAliveTimerFactory {
  static KeepAliveTimer createFromInput(KeepAliveTimerInput input) {
    if (input.existingTimer != null)
      return KeepAliveTimer.from(input.existingTimer!);
    if (input.duration != null && input.callback != null)
      return KeepAliveTimer.periodic(input.duration!, input.callback!);
    throw ArgumentError(
        'KeepAliveTimerInput must include either existingTimer or (duration and callback)');
  }
}

class MessageCallbackMapFactory {
  static MessageCallbackMap create() => MessageCallbackMap();

  static MessageCallbackMap createFromInput() => MessageCallbackMap();
}

class CallbackMapFactory {
  static CallbackMap<T> create<T>() => CallbackMap<T>();

  static CallbackMap<T> createFromInput<T>() => CallbackMap<T>();
}

class AddressUtilityFactory {
  static AddressUtility create() => AddressUtility();

  static AddressUtility createFromInput() => AddressUtility();
}
