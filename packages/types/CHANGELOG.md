# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.7] - 2026-02-08

### Changed
- Updated all dependencies to latest compatible versions
- Version synchronization across all packages in monorepo

## [1.0.6] - 2026-02-05

### Added
- Enhanced callback handler support
- Improved type definitions for better type safety

### Changed
- Refined internal type structures for better integration

## [1.0.5] - 2026-01-30

### Changed
- Updated dependencies to latest versions (json_annotation ^4.10.0, lints ^6.0.0, test ^1.29.0)
- Improved code quality with stricter linting rules
- Removed unnecessary library declaration

### Fixed
- Fixed static analysis warnings for const constructors

## [1.0.1] - 2026-01-12

### Changed
- Removed dependency on `build_runner` and `json_serializable` code generation
- Implemented manual JSON serialization methods for all types
- All generated `.g.dart` files replaced with inline implementations

### Fixed
- Fixed package compatibility issues by eliminating generated code dependencies
- Improved stability by removing build-time code generation requirement

## [1.0.0] - 2026-01-08

### Added
- Initial release of SHSP Types package
- `RemoteInfo` class for representing remote address and port information  
- `PeerTypes` with JSON serialization support
- `StunTypes` for STUN protocol integration
- `InternetAddressConverter` for JSON serialization of IP addresses
- Comprehensive type definitions for Single HandShake Protocol

### Features
- JSON serialization/deserialization support for all types
- IPv4 and IPv6 address support
- Type-safe peer identification and remote info management
- Built-in validation and error handling