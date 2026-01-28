import 'dart:io';
import 'dart:async';

import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import '../utility/message_callback_map.dart';

// Inputs for implementations factories

class ShspSocketInput {
  final RawDatagramSocket socket;
  final MessageCallbackMap? messageCallbacks;

  ShspSocketInput({required this.socket, this.messageCallbacks});
}

class ShspPeerInput {
  final PeerInfo remotePeer;
  final IShspSocket? socket;
  final RawDatagramSocket? rawSocket;

  ShspPeerInput({required this.remotePeer, this.socket, this.rawSocket});
}

class ShspInstanceInput {
  final PeerInfo remotePeer;
  final IShspSocket? socket;
  final RawDatagramSocket? rawSocket;
  final int keepAliveSeconds;

  ShspInstanceInput({
    required this.remotePeer,
    this.socket,
    this.rawSocket,
    this.keepAliveSeconds = 30,
  });
}

class ShspInput {
  final RawDatagramSocket socket;
  final PeerInfo? peerInfo;
  final String? remoteIp;
  final int? remotePort;
  final String signal;

  ShspInput({
    required this.socket,
    this.peerInfo,
    this.remoteIp,
    this.remotePort,
    this.signal = '',
  });
}

// Utility inputs
class ConcatUtilityInput {}

class KeepAliveTimerInput {
  final Timer? existingTimer;
  final Duration? duration;
  final void Function(Timer)? callback;

  KeepAliveTimerInput({this.existingTimer, this.duration, this.callback});
}

class RawShspSocketInput {
  final RawDatagramSocket socket;

  RawShspSocketInput({required this.socket});
}
