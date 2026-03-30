import 'dart:io';
import 'dart:async';

import '../../types/peer_types.dart';
import '../../interfaces/i_shsp_socket.dart';
import '../utility/message_callback_map.dart';

// Inputs for implementations factories

class ShspSocketInput {
  ShspSocketInput({required this.socket, this.messageCallbacks});

  final RawDatagramSocket socket;
  final MessageCallbackMap? messageCallbacks;
}

class ShspPeerInput {
  ShspPeerInput({required this.remotePeer, this.socket, this.rawSocket});

  final PeerInfo remotePeer;
  final IShspSocket? socket;
  final RawDatagramSocket? rawSocket;
}

class ShspInstanceInput {
  ShspInstanceInput({
    required this.remotePeer,
    this.socket,
    this.rawSocket,
    this.keepAliveSeconds = 30,
  });

  final PeerInfo remotePeer;
  final IShspSocket? socket;
  final RawDatagramSocket? rawSocket;
  final int keepAliveSeconds;
}

class ShspInput {
  ShspInput({
    required this.socket,
    this.peerInfo,
    this.remoteIp,
    this.remotePort,
    this.signal = '',
  });

  final RawDatagramSocket socket;
  final PeerInfo? peerInfo;
  final String? remoteIp;
  final int? remotePort;
  final String signal;
}

// Utility inputs
class ConcatUtilityInput {}

class KeepAliveTimerInput {
  KeepAliveTimerInput({this.existingTimer, this.duration, this.callback});

  final Timer? existingTimer;
  final Duration? duration;
  final void Function(Timer)? callback;
}

class RawShspSocketInput {
  RawShspSocketInput({required this.socket});

  final RawDatagramSocket socket;
}
