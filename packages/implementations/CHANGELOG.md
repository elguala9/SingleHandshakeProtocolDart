# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-01-30

### Changed
- Updated dependencies to latest versions (json_annotation ^4.10.0, lints ^6.0.0, test ^1.29.0, meta ^1.18.1)
- Improved code quality with stricter linting rules
- Removed unnecessary library declaration
- Added curly braces to all if statements for better code consistency

### Fixed
- Fixed static analysis warnings (unused fields, flow control structure braces)
- Fixed deprecated API usage warnings
- Fixed documentation HTML comment syntax

## [1.0.1] - 2026-01-11

### Fixed
- Fixed dependencies to use hosted sources instead of path references
- Removed unused imports from `shsp_instance.dart`
- Fixed null comparison in `keep_alive_timer.dart`
- Improved function type syntax for callbacks
- Prepared package for Pub.dev publication

### Changed
- Updated all factory methods with comprehensive documentation
- Added detailed README section on creating SHSP objects

## [1.0.0] - 2026-01-08

### Added
- Initial release of SHSP Implementations package
- `ShspSocket` complete UDP socket implementation with callback management
- `ShspPeer` for peer connection management
- `ShspInstance` for protocol instance management
- `Shsp` core protocol implementation
- Handshake implementations:
  - `HandshakeIp` for IP-based handshakes
  - `HandshakeOwnership` for ownership verification
  - `HandshakeTime` for time-based handshakes
- Utility classes:
  - `CallbackMap` for managing multiple callbacks
  - `MessageCallbackMap` for message-specific callbacks  
  - `AddressUtility` for address formatting
  - `ConcatUtility` for data concatenation
  - `RawShspSocket` for low-level socket operations

### Features
- Complete Single HandShake Protocol implementation
- UDP-based peer-to-peer networking
- Callback-driven asynchronous communication
- Built-in handshake mechanisms for secure connections
- Comprehensive error handling and logging
- Support for IPv4 and IPv6
- Integration with STUN protocol for NAT traversal
- Cryptographic utilities for secure communications