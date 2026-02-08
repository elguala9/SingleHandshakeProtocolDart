# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.7] - 2026-02-08

### Changed
- Updated dependencies: shsp_types ^1.0.7, shsp_interfaces ^1.0.7 (from ^1.0.5)
- Consolidated callback handler integration
- Version synchronization across all packages in monorepo

### Fixed
- Finalized callback handler implementation across all components
- Ensured consistency in callback management patterns

## [1.0.6] - 2026-02-05

### Added
- Callback handler get and set methods
- Enhanced callback management capabilities
- Improved callback lifecycle management

### Changed
- Refactored callback handler to use callback_handler package
- Enhanced ShspInstance callback support
- Improved ShspSocket callback management

### Fixed
- Fixed callback execution and state management
- Resolved issues in message callback mapping

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