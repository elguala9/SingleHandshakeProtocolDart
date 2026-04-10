import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// UDP-based peer communicator for SHSP handshake testing
class PeerCommunicator {
  final String peerId;
  final int listenPort;
  final String remoteHost;
  final int remotePort;

  late RawDatagramSocket socket;
  final StreamController<Map<String, dynamic>> messageController = StreamController.broadcast();

  // Message queue for handling out-of-order packets
  final List<Map<String, dynamic>> messageQueue = [];

  PeerCommunicator({
    required this.peerId,
    required this.listenPort,
    required this.remoteHost,
    required this.remotePort,
  });

  /// Initialize the UDP socket
  Future<void> initialize() async {
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, listenPort);
      print('[$peerId] UDP socket bound to port $listenPort');

      // Start listening for incoming messages
      _startListening();
    } catch (e) {
      print('[$peerId] Failed to initialize socket: $e');
      rethrow;
    }
  }

  /// Start listening for incoming UDP packets
  void _startListening() {
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        _handleIncomingPacket();
      }
    });
  }

  /// Handle incoming UDP packet
  void _handleIncomingPacket() {
    try {
      final datagram = socket.receive();
      if (datagram == null) return;

      final message = utf8.decode(datagram.data);
      final data = jsonDecode(message) as Map<String, dynamic>;

      // Add sender information
      data['_sender_ip'] = datagram.address.address;
      data['_sender_port'] = datagram.port;
      data['_received_time'] = DateTime.now().toIso8601String();

      messageQueue.add(data);
      messageController.add(data);

      print('[$peerId] Received message from ${datagram.address.address}:${datagram.port}');
    } catch (e) {
      print('[$peerId] Error handling incoming packet: $e');
    }
  }

  /// Send a message to the remote peer
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    try {
      // Add sender identification
      message['_sent_from'] = peerId;
      message['_sent_time'] = DateTime.now().toIso8601String();

      final data = utf8.encode(jsonEncode(message));

      // Try to resolve remote host
      final addresses = await InternetAddress.lookup(remoteHost);
      if (addresses.isEmpty) {
        print('[$peerId] Failed to resolve host: $remoteHost');
        return false;
      }

      final bytesSent = socket.send(data, addresses.first, remotePort);
      print('[$peerId] Sent $bytesSent bytes to $remoteHost:$remotePort');

      return bytesSent > 0;
    } catch (e) {
      print('[$peerId] Error sending message: $e');
      return false;
    }
  }

  /// Wait for a specific message type with timeout
  Future<Map<String, dynamic>?> waitForMessage(
    String messageType, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final stream = messageController.stream
          .where((msg) => msg['type'] == messageType || msg['messageType'] == messageType);

      return await stream.first.timeout(timeout);
    } on TimeoutException {
      print('[$peerId] Timeout waiting for message type: $messageType');
      return null;
    } catch (e) {
      print('[$peerId] Error waiting for message: $e');
      return null;
    }
  }

  /// Get all messages of a specific type
  List<Map<String, dynamic>> getMessages(String messageType) {
    return messageQueue
        .where((msg) => msg['type'] == messageType || msg['messageType'] == messageType)
        .toList();
  }

  /// Close the communicator
  Future<void> close() async {
    socket.close();
    await messageController.close();
  }

  /// Get socket information
  Map<String, dynamic> getSocketInfo() {
    return {
      'local_address': socket.address.address,
      'local_port': socket.port,
      'remote_host': remoteHost,
      'remote_port': remotePort,
    };
  }
}

/// Helper class for peer-to-peer handshake
class HandshakeHelper {
  final PeerCommunicator communicator;

  HandshakeHelper(this.communicator);

  /// Initiate handshake from this peer
  Future<Map<String, dynamic>?> initiateHandshake({
    required String localIp,
    required int localPort,
  }) async {
    print('[HANDSHAKE] Initiating handshake...');

    final handshakeMessage = {
      'type': 'HANDSHAKE_INIT',
      'localIp': localIp,
      'localPort': localPort,
      'peerId': communicator.peerId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final success = await communicator.sendMessage(handshakeMessage);
    if (!success) {
      print('[HANDSHAKE] Failed to send handshake message');
      return null;
    }

    // Wait for response
    return await communicator.waitForMessage('HANDSHAKE_RESPONSE');
  }

  /// Handle incoming handshake request
  Future<void> handleHandshakeRequest({
    required String localIp,
    required int localPort,
  }) async {
    print('[HANDSHAKE] Waiting for handshake request...');

    final request = await communicator.waitForMessage('HANDSHAKE_INIT');
    if (request == null) {
      print('[HANDSHAKE] No handshake request received');
      return;
    }

    print('[HANDSHAKE] Received handshake from ${request['peerId']}');

    // Send response
    final response = {
      'type': 'HANDSHAKE_RESPONSE',
      'localIp': localIp,
      'localPort': localPort,
      'peerId': communicator.peerId,
      'remoteIp': request['_sender_ip'],
      'remotePort': request['_sender_port'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    await communicator.sendMessage(response);
    print('[HANDSHAKE] Sent handshake response');
  }

  /// Exchange IP information with peer
  Future<Map<String, dynamic>?> exchangeIpInfo({
    required String localIp,
    required int localPort,
    required String publicIp,
  }) async {
    final infoMessage = {
      'type': 'IP_INFO',
      'localIp': localIp,
      'localPort': localPort,
      'publicIp': publicIp,
      'peerId': communicator.peerId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await communicator.sendMessage(infoMessage);
    return await communicator.waitForMessage('IP_INFO');
  }
}
