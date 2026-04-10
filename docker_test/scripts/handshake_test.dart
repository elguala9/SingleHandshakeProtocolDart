import 'dart:io';
import 'dart:async';
import 'dart:convert';

class TestResult {
  final String peerId;
  final String natType;
  final String status;
  final String? errorMessage;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;

  TestResult({
    required this.peerId,
    required this.natType,
    required this.status,
    this.errorMessage,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'natType': natType,
      'status': status,
      'errorMessage': errorMessage,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
    };
  }
}

Future<void> main(List<String> args) async {
  String? peerId;
  int? peerPort;
  String? remoteHost;
  int? remotePort;
  String? natType;
  String? localIp;
  String resultsDir = './results';

  // Parse arguments
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--peer-id':
        peerId = args[++i];
        break;
      case '--peer-port':
        peerPort = int.parse(args[++i]);
        break;
      case '--remote-host':
        remoteHost = args[++i];
        break;
      case '--remote-port':
        remotePort = int.parse(args[++i]);
        break;
      case '--nat-type':
        natType = args[++i];
        break;
      case '--local-ip':
        localIp = args[++i];
        break;
      case '--results-dir':
        resultsDir = args[++i];
        break;
    }
  }

  if (peerId == null || peerPort == null || remoteHost == null || remotePort == null || natType == null || localIp == null) {
    print('Usage: dart handshake_test.dart --peer-id <id> --peer-port <port> --remote-host <host> --remote-port <port> --nat-type <type> --local-ip <ip> --results-dir <dir>');
    exit(1);
  }

  final startTime = DateTime.now();
  final results = <TestResult>[];

  try {
    print('[$peerId] Starting SHSP Handshake Test');
    print('[$peerId] NAT Type: $natType');
    print('[$peerId] Local: $localIp:$peerPort');
    print('[$peerId] Remote: $remoteHost:$remotePort');

    // Create results directory
    await Directory(resultsDir).create(recursive: true);

    // Bind UDP socket
    final socket = await RawDatagramSocket.bind(localIp, peerPort);
    print('[$peerId] UDP socket bound to $localIp:$peerPort');

    // Prepare handshake packet
    final packet = {
      'peerId': peerId,
      'natType': natType,
      'timestamp': DateTime.now().toIso8601String(),
      'localIp': localIp,
      'localPort': peerPort,
    };

    // Send handshake packet
    try {
      final addresses = await InternetAddress.lookup(remoteHost);
      if (addresses.isEmpty) {
        throw Exception('Cannot resolve $remoteHost');
      }

      final packetData = utf8.encode(jsonEncode(packet));
      final bytesSent = socket.send(packetData, addresses.first, remotePort);

      print('[$peerId] Sent $bytesSent bytes to $remoteHost:$remotePort');

      // Wait for response or timeout
      bool responseReceived = false;
      late StreamSubscription sub;

      final future = Future.delayed(const Duration(seconds: 10)).then((_) {
        if (!responseReceived) {
          sub.cancel();
        }
      });

      try {
        sub = socket.asBroadcastStream().listen((event) {
          if (event == RawSocketEvent.read && !responseReceived) {
            final datagram = socket.receive();
            if (datagram != null) {
              responseReceived = true;
              print('[$peerId] Received response from ${datagram.address.address}:${datagram.port}');
              sub.cancel();
            }
          }
        });

        await future;

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;

        results.add(TestResult(
          peerId: peerId,
          natType: natType,
          status: responseReceived ? 'SUCCESS' : 'TIMEOUT',
          startTime: startTime,
          endTime: endTime,
          duration: duration,
        ));

        print('[$peerId] Test completed: ${results.last.status}');
      } finally {
        socket.close();
      }
    } catch (e) {
      final endTime = DateTime.now();
      print('[$peerId] Error: $e');

      results.add(TestResult(
        peerId: peerId,
        natType: natType,
        status: 'ERROR',
        errorMessage: e.toString(),
        startTime: startTime,
        endTime: endTime,
        duration: endTime.difference(startTime).inMilliseconds,
      ));
    }

    // Save results
    final resultsFile = File('$resultsDir/${peerId}_results.json');
    final resultsJson = {
      'test': 'SHSP Handshake NAT Test',
      'timestamp': DateTime.now().toIso8601String(),
      'peerId': peerId,
      'natType': natType,
      'results': results.map((r) => r.toJson()).toList(),
    };

    await resultsFile.writeAsString(jsonEncode(resultsJson));
    print('[$peerId] Results saved to ${resultsFile.path}');
    print('[$peerId] Results: ${jsonEncode(resultsJson)}');
  } catch (e) {
    print('[$peerId] Fatal error: $e');
    exit(1);
  }
}
