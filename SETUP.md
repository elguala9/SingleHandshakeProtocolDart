# Setup Instructions - Monorepo

## Prerequisites

### Install Dart SDK

Since you'll be running this on both backend and mobile, you have two options:

#### Option 1: Install Flutter (Recommended for Mobile + Backend)
Flutter includes Dart SDK, so you get both:

1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
2. Extract it to a location like `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Run: `flutter doctor` to verify installation

#### Option 2: Install Dart SDK Only (Backend Only)
If you only need backend functionality:

1. Download Dart SDK from: https://dart.dev/get-dart
2. Extract and add to PATH
3. Verify with: `dart --version`

## After Installing Dart/Flutter

### 1. Install All Package Dependencies

Using the provided script (Windows):
```powershell
.\install_all.bat
```

Or manually:
```powershell
cd packages\types
dart pub get

cd ..\interfaces
dart pub get

cd ..\implementations
dart pub get

cd ..\tests
dart pub get

cd ..\..
```

### 2. Run Tests

```powershell
cd packages\tests
dart test
```

### 3. Run Examples

Backend example:
```powershell
dart run bin\backend_main.dart
```

Socket example:
```powershell
dart run example\socket_example.dart
```

## Monorepo Structure

```
SingleHandShakeProtocolDart/
├── packages/
│   ├── types/                      # Type definitions
│   │   ├── lib/
│   │   │   ├── shsp_types.dart
│   │   │   └── src/
│   │   │       └── remote_info.dart
│   │   └── pubspec.yaml
│   │
│   ├── interfaces/                 # Interface contracts
│   │   ├── lib/
│   │   │   ├── shsp_interfaces.dart
│   │   │   └── src/
│   │   │       └── i_shsp_socket.dart
│   │   └── pubspec.yaml
│   │
│   ├── implementations/            # Concrete implementations
│   │   ├── lib/
│   │   │   ├── shsp_implementations.dart
│   │   │   └── src/
│   │   │       ├── shsp_socket.dart
│   │   │       ├── handshake_protocol.dart
│   │   │       └── utility/
│   │   │           ├── callback_map.dart
│   │   │           └── address_utility.dart
│   │   └── pubspec.yaml
│   │
│   └── tests/                      # Test suite
│       ├── test/
│       │   ├── socket_test.dart
│       │   └── handshake_protocol_test.dart
│       └── pubspec.yaml
│
├── bin/                            # Executable examples
├── example/                        # Usage examples
├── pubspec.yaml                    # Root package
├── install_all.bat                 # Dependency installer
└── README.md
```

## Using in Your Projects

### In a Dart/Backend Project

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp_types:
    path: ../SingleHandShakeProtocolDart/packages/types
  shsp_interfaces:
    path: ../SingleHandShakeProtocolDart/packages/interfaces
  shsp_implementations:
    path: ../SingleHandShakeProtocolDart/packages/implementations
```

Then import what you need:

```dart
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
```

### In a Flutter/Mobile Project

Same as above - all packages are platform-agnostic.

## Development Workflow

1. **Make changes** to any package
2. **Run tests** from the tests package: `cd packages\tests && dart test`
3. **Test in examples** if needed
4. Changes are automatically reflected in dependent packages (path dependencies)

## Package Dependencies

```
shsp_types (no dependencies)
    ↓
shsp_interfaces (depends on: types)
    ↓
shsp_implementations (depends on: types, interfaces)
    ↓
shsp_tests (depends on: all packages)
```

## Next Steps

1. Install Dart SDK or Flutter SDK
2. Run `.\install_all.bat` to install all dependencies
3. Run tests: `cd packages\tests && dart test`
4. Explore examples in `bin\` and `example\`
5. Start building your handshake protocol!
