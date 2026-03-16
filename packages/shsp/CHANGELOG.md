# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Analyzer Issues**: Resolved all Dart analyzer warnings and errors
  - Removed unused local variables
  - Added missing test dependencies (`singleton_manager`)
  - Updated deprecated callback setters to use new `CallbackHandler.register()` pattern
    - `setListeningCallback()` → `onListening.register((_) {})`
    - `setCloseCallback()` → `onClose.register((_) {})`
    - `setErrorCallback()` → `onError.register((_) {})`

## [1.2.1] - 2026-03-14

### Added

- **Initialize Point Function**: New `initializePointShsp()` function for convenient singleton setup
  - Automatically initializes IPv4 and IPv6 sockets
  - Handles IPv6 availability detection
  - Sets up dual socket and registry singleton
- **Socket Wrapper**: New `ShspSocketWrapper` class for transparent socket replacement
  - Implements proxy pattern to allow underlying socket swapping
  - Maintains stable references while supporting socket migration
  - Enables graceful socket reconnection and state transfer

### Changed

- Improved singleton initialization pattern with dedicated entry point
- Registry initialization now integrated into centralized initialization flow

## [1.2.0] - 2026-03-11

### Added

- **Registry System**: New generic registry pattern with mixin-based API for managing multiple instances:
  - `Registry<Key, Value>` mixin for key-value based instance management
  - `Singleton` class for type-based instance management
  - `IValueForRegistry` interface for registry-managed objects
  - `RegistryMixin` trait for registering and managing sockets/peers
- **Extended Interface Support**: Socket and peer interfaces now support registry integration:
  - `IShspSocket` implements `IValueForRegistry` with `destroy()` method
  - `IShspPeer` implements `IValueForRegistry` with proper cleanup
- **Socket Type Enumeration**: New `SocketType` enum for IPv4/IPv6 socket management
- **Registry Utilities**: Helper functions for socket registry initialization and management

### Changed

- **Registry Version Preservation**: Registry now preserves element version during updates instead of incrementing
  - `register()` maintains the existing version when updating an element
  - New elements are initialized with version 0
  - This enables stable version tracking across updates

### Fixed

- Improved resource cleanup with `destroy()` methods throughout the API
- Better type safety with registry-based instance management

## [1.0.0] - 2026-03-10

### Added

- Initial release of the unified SHSP (Single HandShake Protocol) package
- Core networking protocol implementation for peer-to-peer communication over UDP
- `ShspSocket`: Main UDP socket implementation with callback management
- `ShspPeer`: High-level peer abstraction for bidirectional communication
- `ShspInstance`: Protocol instance with automatic keep-alive support
- `ShspSocketSingleton`: Global socket management with state transfer and reconnection support
- `AutoShspPeer`: Auto-wiring peer that binds to `ShspSocketSingleton` with automatic reconnection
- `AutoShspInstance`: Auto-wiring instance with automatic socket management
- Compression support with three pluggable codecs:
  - `GZipCodec`: Best compression ratio
  - `LZ4Codec`: Fast compression with reasonable ratios
  - `ZstdCodec`: Balanced compression and speed
- Comprehensive type definitions:
  - `RemoteInfo`: Address and port information
  - `SocketProfile`: Socket configuration and state tracking
  - `InstanceProfile`: Instance configuration and state tracking
  - Callback type definitions for various protocol events
- IPv4 and IPv6 support with automatic address formatting
- Dual-stack socket support for seamless IPv4/IPv6 interoperability
- `CallbackMap` and `MessageCallbackMap` utilities for managing callbacks
- `AddressUtility` for address formatting
- Complete interface contracts for extensibility
- 399+ comprehensive tests ensuring reliability
- Multi-platform support (Dart CLI, Flutter mobile, web)
- Comprehensive documentation and examples
- GitHub Actions CI/CD pipeline
- LGPL-3.0 license

### Features

- Automatic handshake with configurable timeouts and retry intervals
- Configurable keep-alive heartbeat (default: 30 seconds)
- Non-blocking async/await API throughout
- Singleton pattern for global socket management
- Callback-based message/data reception
- Automatic socket state management and reconnection
- Extensible compression codec interface
- Full type safety with Dart type system
