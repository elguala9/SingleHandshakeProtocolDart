# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.7.0] - 2026-03-30

### Added

- `IDualShspSocketWrapper` interface for `DualShspSocketWrapper`/`DualShspSocketWrapperDI` proxy
- `IRegistryShspSocket` interface for `RegistryShspSocket`

### Changed

- `buildDualSocket()` now returns `IDualShspSocketMigratable` instead of `DualShspSocketMigratable`
- `initializePointDualShsp()` registers registry under `IRegistryShspSocket` interface
- `initializePointRegistryAccess()` uses `IDualShspSocketWrapper` and `IRegistryShspSocket` as registration keys
- `DualShspSocketWrapper` now explicitly implements `IDualShspSocketWrapper`
- `RegistryShspSocket` now explicitly implements `IRegistryShspSocket`
- `ShspHandshakeHandler.handshakeInstance` rewritten as event-driven (Completer + Timer.periodic) instead of polling; eliminates a race condition where the `onOpen` callback was never invoked when the socket read event and the delay timer fired in the same event-loop tick

## [1.6.1] - 2026-03-30

### Changed

- Updated `singleton_manager` dependency from `^0.5.0` to `^0.6.1`

## [1.6.0] - 2026-03-26

### Changed

- Updated `singleton_manager` dependency from `^0.4.0` to `^0.5.0`
- Updated `singleton_manager_generator` dev dependency from `^1.0.4` to `^1.2.0`
- Renamed `isClosing()` to `isClosingMessage()` in `ShspInstanceHandshakeMixin`
- Renamed `isClosed()` to `isClosedMessage()` in `ShspInstanceHandshakeMixin`

### Removed

- Removed `archive` dependency

## [1.5.0] - 2026-03-20

### Changed

- **`IDualShspSocketMigratable` is now the primary DI type** replacing `IDualShspSocket` throughout the framework
  - `initializePointDualShsp()` now creates a `DualShspSocketMigratable` (instead of `DualShspSocket`) and registers it under `IDualShspSocketMigratable`
  - `DualShspSocketWrapper.dualSocket` and `internalSocket` setter are now typed `IDualShspSocketMigratable`
  - `ISimpleDualSocketSingleton.getInstance()` / `setInstance()` now use `IDualShspSocketMigratable`
  - `RegistryShspSocket.initialize()` now accepts `IDualShspSocketMigratable`; `bind()` creates `DualShspSocketMigratable` internally
  - `RegistryShspSocket.initializeDI()` resolves `IDualShspSocketMigratable` from DI

### Breaking Changes

- `SingletonDIAccess.get<IDualShspSocket>()` is no longer registered by `initializePointDualShsp()` — use `get<IDualShspSocketMigratable>()` instead
- `ISimpleDualSocketSingleton.setInstance()` now requires an `IDualShspSocketMigratable`; plain `IDualShspSocket` instances are no longer accepted

## [1.4.0] - 2026-03-20

### Added

- **`IShspSocketWrapper` interface**: New contract for socket proxy/wrapper classes
  - `migrateSocket(IShspSocket newSocket)` — swaps the underlying socket and re-applies stored callbacks
- **`IDualShspSocketMigratable` interface**: Contract for dual-socket migration
  - `migrateSocketIpv4(IShspSocket socket)` — replaces the IPv4 underlying socket
  - `migrateSocketIpv6(IShspSocket socket)` — replaces or adds the IPv6 underlying socket
- **`DualShspSocketMigratable`**: New class extending `DualShspSocket` that implements `IDualShspSocketMigratable`
  - Wraps raw sockets in `ShspSocketWrapper` automatically via its default constructor
  - `fromWrappers` named constructor for pre-wrapped socket injection
  - Enables live socket migration without losing peer callbacks or references

### Changed

- **`ShspSocketWrapper`** now implements `IShspSocketWrapper` instead of bare `IShspSocket`
  - Added anti-nesting guard: wrapping another `ShspSocketWrapper` throws `ArgumentError`
  - Stores listening, close, and error callbacks internally so they are re-applied on every `migrateSocket()` call

## [1.3.0] - 2026-03-19

### Added

- **`IShspSocket` implements `RawDatagramSocket`**: The socket interface now extends `RawDatagramSocket` directly,
  making `IShspSocket` a full drop-in replacement for `RawDatagramSocket` in any Dart API
  - `ShspSocketWrapper` provides complete delegation of all `RawDatagramSocket` members
    (`address`, `port`, `send`, `receive`, `broadcastEnabled`, `multicastLoopback`, `multicastHops`,
    `multicastInterface`, `readEventsEnabled`, `writeEventsEnabled`, `joinMulticast`, `leaveMulticast`, etc.)
  - Added `_raw` computed getter in `ShspSocketWrapper` — automatically reflects the current underlying socket after any swap

### Changed

- **`IShspSocket`**: Added explicit `destroy()` method to the interface contract
- **`IDualShspSocket`**: Removed redundant `socket` getter — `RawDatagramSocket` access is now inherited through `IShspSocket`
- **`DualShspSocketWrapper`**: Removed `socket` override for the same reason
- Removed redundant imports in `dual_shsp_socket.dart` and `initialize_point.dart`

### Breaking Changes

- Any class implementing `IShspSocket` must now also implement all `RawDatagramSocket` members

## [1.2.4] - 2026-03-19

### Fixed

- **Incomplete `shsp.dart` barrel**: Regenerated root library with all missing exports
  - Added factory interfaces: `i_shsp_instance_factory`, `i_shsp_peer_factory`, `i_shsp_socket_factory`
  - Added utility interfaces: `i_address_utility`, `i_callback_map`, `i_keep_alive_timer`, `i_message_callback_map`, `i_message_callback_map_singleton`, `i_raw_shsp_socket`, `i_shsp_socket_info_singleton`
  - Added socket features: `shsp_socket_callbacks`, `shsp_socket_compression`, `shsp_socket_profile`
  - Added dual socket: `dual_shsp_socket_message`, `dual_shsp_socket_profile`
  - Reorganized exports in alphabetical/logical order

## [1.2.3] - 2026-03-19

### Fixed

- **Missing Index Export**: Added `i_shsp_socket_base.dart` to `src/interfaces/index.dart`
  - The interface was accessible via the root `shsp.dart` but missing from the sub-index barrel

## [1.2.2] - 2026-03-19

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

- **Initialize Point Function**: New `initializePointDualShsp()` function for convenient singleton setup
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
