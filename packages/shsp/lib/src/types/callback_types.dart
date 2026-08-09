import 'package:callback_handler/implementations/callback_handler.dart';

import '../../shsp.dart';

/// Record type for message callbacks containing the message bytes and sender info
typedef MessageRecord = ({List<int> msg, RemoteInfo rinfo});

/// Function type for message callbacks with positional parameters
typedef MessageCallbackFunction = void Function(MessageRecord);
typedef CallbackOn = CallbackHandler<void, void>;
typedef CallbackOnError = CallbackHandler<dynamic, void>;

typedef ErrorWithSocket = ({
  dynamic error,
  IShspSocket socket
});

typedef CallbackOnErrorWithSocket = CallbackHandler<ErrorWithSocket, void>;
typedef CallbackOnWithSocket = CallbackHandler<IShspSocket, void>;


typedef MessageCallback = CallbackHandler<PeerInfo, void>;

typedef MessageWithSocket = ({
  PeerInfo peerInfo,
  IShspSocket socket
});
typedef MessageCallbackWithSocket = CallbackHandler<PeerInfo, void>;