import 'remote_info.dart';

/// Record type for message callbacks containing the message bytes and sender info
typedef MessageRecord = ({List<int> msg, RemoteInfo rinfo});

/// Function type for message callbacks with positional parameters
typedef MessageCallbackFunction = void Function(MessageRecord);
