/// SHSP Instance with Keep-Alive Example
///
/// This example demonstrates:
/// - Creating an instance with keep-alive support
/// - Long-lived connections
/// - Receiving data with lifecycle callbacks

import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  // Create an instance with 30-second keep-alive
  final instance = await AutoShspInstance.create(
    remoteInfo: RemoteInfo.fromString('127.0.0.1:9000')!,
    keepAliveSeconds: 30,
  );

  print('Instance created and handshaking with remote peer...');

  // Register lifecycle callbacks
  instance.onHandshake(() {
    print('✓ Handshake completed - connection established');
  });

  instance.onOpening(() {
    print('→ Connection opening...');
  });

  instance.onData((data) {
    print('← Received ${data.length} bytes');
  });

  instance.onClosing(() {
    print('← Connection closing...');
  });

  instance.onClose(() {
    print('✗ Connection closed');
  });

  // Send some data
  final data = Uint8List.fromList(List.generate(10, (i) => i));
  await instance.sendData(data);
  print('Sent ${data.length} bytes');

  // Keep the instance alive for communication
  await Future.delayed(Duration(seconds: 5));

  // Close the connection
  await instance.close();
  print('Instance closed');
}
