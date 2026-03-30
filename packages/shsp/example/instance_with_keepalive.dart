import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  // Create an instance with 30-second keep-alive
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9000,
  );

  print('Creating instance with keep-alive support...');

  final instance = await AutoShspInstance.create(
    remotePeer: remotePeer,
    keepAliveSeconds: 30,
  );

  print('✓ Instance created');
  print(
    '  Local: ${instance.socket.localAddress}:${instance.socket.localPort}',
  );
  print('  Remote: ${remotePeer.address.address}:${remotePeer.port}');
  print('  Keep-alive: 30 seconds');

  // Send some data
  final data = Uint8List.fromList(List.generate(10, (i) => i));
  instance.sendMessage(data);
  print('\n✓ Sent ${data.length} bytes');

  // Keep the instance alive for communication
  print('Keeping connection alive for 5 seconds...');
  await Future.delayed(const Duration(seconds: 5));

  // Close the connection
  instance.close();
  print('\n✓ Instance closed');
}
