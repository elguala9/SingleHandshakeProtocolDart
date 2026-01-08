# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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