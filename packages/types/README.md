# SHSP Types

Type definitions for the Single HandShake Protocol.

## Contents

- `RemoteInfo`: Class representing remote address and port information

## Usage

```dart
import 'package:shsp_types/shsp_types.dart';

final rinfo = RemoteInfo(InternetAddress.loopbackIPv4, 8080);
print(rinfo); // 127.0.0.1:8080
```
