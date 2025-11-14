# SHSP Implementations

Concrete implementations for the Single HandShake Protocol.

## Contents

- `ShspSocket`: UDP socket implementation with callback management
- `HandshakeProtocol`: Core handshake protocol logic
- `CallbackMap`: Utility for managing multiple callbacks
- `AddressUtility`: Utility for formatting addresses

## Dependencies

- `shsp_types`: For type definitions
- `shsp_interfaces`: For interface contracts

## Usage

```dart
import 'package:shsp_implementations/shsp_implementations.dart';
import 'dart:io';

void main() async {
  final socket = ShspSocket();
  
  socket.setListeningCallback(() {
    print('Socket listening');
  });
  
  await socket.bind(InternetAddress.loopbackIPv4, 8080);
}
```
