# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- 11 new public interfaces for better extensibility and dependency injection:
  - Factory interfaces: `IShspSocketFactory`, `IShspPeerFactory`, `IShspInstanceFactory`
  - Utility interfaces: `IAddressUtility`, `ICallbackMap<T>`, `IKeepAliveTimer`, `IMessageCallbackMap`
  - Socket interfaces: `IRawShspSocket`, `IDualShspSocket`
  - Singleton interfaces: `IMessageCallbackMapSingleton`, `IShspSocketInfoSingleton`
- All @override annotations for better code clarity

### Fixed

- Resolved all dart analyze warnings (36 missing @override annotations)
- API consistency for singleton destroy methods

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
