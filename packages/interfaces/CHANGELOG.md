# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-08

### Added
- Initial release of SHSP Interfaces package
- `IShspSocket` interface for socket implementations
- `IShspPeer` interface for peer management
- `IShspInstance` interface for protocol instances  
- `IShsp` core protocol interface
- `IShspHandshake` and `IShspHandshakeHandler` interfaces for handshake management
- Complete API contracts for Single HandShake Protocol implementations

### Features
- Abstract interfaces defining the core SHSP API
- Type-safe contracts for all protocol components
- Comprehensive documentation for implementers
- Dependency on shsp_types for shared type definitions