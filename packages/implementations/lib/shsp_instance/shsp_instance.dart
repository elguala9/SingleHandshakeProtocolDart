
import 'package:shsp_implementations/shsp_implementations.dart';
// ...existing code...
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

const int dataPrefix = 0x00;
const int handshakePrefix = 0x01;
const int closingPrefix = 0x02;
const int closedPrefix = 0x03;
const int keepAlivePrefix = 0x04;

// TO DO (Extension) : Add callback for extra data after prefixes (eg. handshake with data)

/// Istanza SHSP: gestisce handshake, chiusura, keep-alive e messaggi dati.
class ShspInstance extends ShspPeer implements IShspInstance {
  bool _handshake = false;
  bool _closing = false;
  bool _open = false;
  int _keepAliveSeconds;
  KeepAliveTimer? _keepAliveTimer;

  void Function()? _onHandshake;
  void Function()? _onOpen;
  void Function()? _onClosing;
  void Function()? _onClosed;
  @override
  void setCallbacks({
    required void Function()? onHandshake,
    required void Function()? onOpen,
    required void Function()? onClosing,
    required void Function()? onClosed,
  }) {
    _onHandshake = onHandshake;
    _onOpen = onOpen;
    _onClosing = onClosing;
    _onClosed = onClosed;
  }

  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 30,
  }) : _keepAliveSeconds = keepAliveSeconds;

  /// Factory: crea una nuova istanza SHSP con keep-alive configurabile.
  factory ShspInstance.create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    int keepAliveSeconds = 30,
  }) {
    return ShspInstance(
      remotePeer: remotePeer,
      socket: socket,
      keepAliveSeconds: keepAliveSeconds,
    );
  }

  /// Factory: crea una nuova istanza SHSP da uno ShspPeer esistente.
  factory ShspInstance.fromPeer(
    ShspPeer peer, {
    int keepAliveSeconds = 30,
  }) {
    return ShspInstance(
      remotePeer: peer.remotePeer,
      socket: peer.socket,
      keepAliveSeconds: keepAliveSeconds,
    );
  }

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    print('ShspInstance.onMessage chiamata: $msg'); // test
    // Check protocol messages first
    if (_isHandshake(msg)) return;
    if (_isClosing(msg)) return;
    if (_isClosed(msg)) return;
    if (_isKeepAlive(msg)) return;

    // Pass to parent for user callback
    if(_isData(msg)) super.onMessage(msg, info);

    throw Exception('Message type not recognized by ShspInstance: $msg');
  }

  bool _isData(List<int> msg) {
    print('ShspInstance._isData chiamata'); // test
    if (msg.isNotEmpty && msg[0] == dataPrefix) {
      return true;
    }
    return false;
  }

  /// Check if message is a handshake (0x01)
  bool _isHandshake(List<int> msg) {
    print('ShspInstance._isHandshake chiamata'); // test
    if (msg.isNotEmpty && msg[0] == handshakePrefix) {
      _handshake = true; // i got the handshake of the other peer
      if (_onHandshake != null) _onHandshake!();
      // if [0x01, 0x01] then the other peer got my handshake
      if(msg.length > 1 && msg[1] == handshakePrefix){
        _open = true;
        if (_onOpen != null) _onOpen!();
      }
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x02)
  bool _isClosing(List<int> msg) {
    print('ShspInstance._isClosing chiamata'); // test
    if (msg.isNotEmpty && msg[0] == closingPrefix) {
      _closing = true;
      if (_onClosing != null) _onClosing!();
      return true;
    }
    return false;
  }

  /// Check if message is a closed signal (0x03)
  bool _isClosed(List<int> msg) {
    print('ShspInstance._isClosed chiamata'); // test
    if (msg.isNotEmpty && msg[0] == closedPrefix) {
      _closing = false;
      _open = false;
      if (_onClosed != null) _onClosed!();
      return true;
    }
    return false;
  }

  /// Check if message is a keep-alive (0x04)
  bool _isKeepAlive(List<int> msg) {
    print('ShspInstance._isKeepAlive chiamata'); // test
    if (msg.isNotEmpty && msg[0] == keepAlivePrefix) {
      return true;
    }
    return false;
  }

  @override
  bool get handshake => _handshake;

  @override
  bool get closing => _closing;

  @override
  bool get open => _open;

  @override
  int get keepAliveSeconds => _keepAliveSeconds;

  @override
  set keepAliveSeconds(int seconds) {
    _keepAliveSeconds = seconds;
    stopKeepAlive();
    startKeepAlive();
  }
  
    
  @override
  void sendHandshake() {
    print('ShspInstance.sendHandshake chiamata'); // test
    List<int> msg = [handshakePrefix];
    if(_handshake) { // if i got the handshake i add a 0x01 to inform the other peer
      msg.add(handshakePrefix);
    }
    _sendMessage(msg);
  }

  @override
  void keepAlive() {
    print('ShspInstance.keepAlive chiamata'); // test
    if(closing || !open) return; // do not send keep-alive if closing or closed
    _sendMessage([keepAlivePrefix]);
  }
  
  @override
  void sendClosing() {
    print('ShspInstance.sendClosing chiamata'); // test
    _sendMessage([closingPrefix]);
    _closing = true;
  }

  @override
  void sendClosed() {
    print('ShspInstance.sendClosed chiamata'); // test
    _sendMessageNoCheck([closedPrefix]);
    _closing = false;
    _open = false;
  }

  /// Avvia l'invio periodico di keep-alive.
  @override
  void startKeepAlive() {
    print('ShspInstance.startKeepAlive chiamata'); // test
    if (_keepAliveTimer != null && _keepAliveTimer!.isActive) {
      return; // Already running
    }
    _keepAliveTimer = KeepAliveTimer.periodic(
      Duration(seconds: keepAliveSeconds),
      (_) {
        keepAlive();
      },
    );
  }

  /// Ferma l'invio periodico di keep-alive.
  @override
  void stopKeepAlive() {
   print('ShspInstance.stopKeepAlive chiamata'); // test
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// Reset del timer keep-alive (posticipa il prossimo invio).
  void resetKeepAlive() {
    print('ShspInstance.resetKeepAlive chiamata'); // test
    _keepAliveTimer?.resetTick();
  }

  @override
  void sendMessage(List<int> message) {
    print('ShspInstance.sendMessage chiamata'); // test
    message.insert(0, dataPrefix);
    if(open == false) throw Exception('Cannot send message: connection is not open.');
    _sendMessage(message);
  }

  void _sendMessage(List<int> message) {
    print('ShspInstance._sendMessage chiamata. $message'); // test
    if(closing == true) throw Exception('Cannot send message: connection is closing.');

    _sendMessageNoCheck(message);
    // Reset keep-alive timer on any outgoing message 
    resetKeepAlive();
  }

  void _sendMessageNoCheck(List<int> message) {
    print('ShspInstance._sendMessageNoCheck chiamata. $message'); // test
    super.sendMessage(message);
  }

}
