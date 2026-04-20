# Setup Instructions - Unified SHSP Package

> **Note:** As of v1.8.0, SHSP is a single unified package. The previous multi-package structure (types, interfaces, implementations) has been consolidated into `packages/shsp/`.

## Prerequisites

### Install Dart SDK

Since you can run this on both backend and mobile, you have two options:

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

## Quick Start

### 1. Install Dependencies

```bash
cd packages/shsp
dart pub get
```

### 2. Run Tests

```bash
cd packages/shsp
dart test
```

### 3. Run Examples

```bash
cd packages/shsp
dart run example/socket_example.dart
```

## Project Structure

```
SingleHandShakeProtocolDart/
├── packages/
│   ├── shsp/                   # Main unified SHSP package (v1.8.0)
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── interfaces/     # Protocol contracts
│   │   │   │   ├── types/          # Type definitions
│   │   │   │   ├── impl/           # Concrete implementations
│   │   │   │   └── utility/        # Helper utilities
│   │   │   └── shsp.dart           # Main export
│   │   ├── example/                # Usage examples
│   │   ├── test/                   # Test suite (625+ tests)
│   │   ├── pubspec.yaml
│   │   └── README.md               # Package documentation
│   │
│   └── tests/                  # Deprecated - tests now in packages/shsp/test
│
├── docker_test/                # Docker-based NAT testing
├── README.md                   # This repository's documentation
└── CHANGELOG.md                # Version history
```

## Using SHSP in Your Projects

### Using from pub.dev (Recommended)

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp: ^1.8.0
```

Then run:

```bash
dart pub get
```

### Using from Git (Development)

```yaml
dependencies:
  shsp:
    git:
      url: https://github.com/lgualandi/SingleHandShakeProtocolDart
      path: packages/shsp
```

### Using from Local Path

```yaml
dependencies:
  shsp:
    path: ../SingleHandShakeProtocolDart/packages/shsp
```

## Next Steps

1. Install Dart SDK or Flutter SDK
2. Run tests: `cd packages/shsp && dart test`
3. Explore examples in `packages/shsp/example/`
4. Read the [SHSP README](packages/shsp/README.md) for detailed API documentation
5. Start building with SHSP!
