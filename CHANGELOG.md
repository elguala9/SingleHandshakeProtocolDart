# Changelog

All notable changes to the Single HandShake Protocol monorepo are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - 2026-04-20

### Added

#### Comprehensive Test Suite Expansion
- **625+ passing tests** - Significantly expanded test coverage across all protocol components
- Enhanced test coverage for:
  - Socket creation and lifecycle management
  - Message callback mapping with IPv4/IPv6 support
  - Handshake protocol validation
  - Keep-alive mechanism testing
  - Compression codec validation (GZip, LZ4, Zstd)
  - Socket migration scenarios
  - Registry management patterns
  - Auto-wiring peer/instance functionality
  - Singleton management and DI integration

### Fixed

#### Code Quality
- Fixed MessageCallbackMap implementation and test coverage
- Fixed Dart analysis issues for pub.dev compliance
- Minor Dart SDK compatibility fixes

## [1.7.1] - 2026-04-11

### Fixed

#### Code Quality
- Removed unused import `dart:typed_data` from peer_communicator.dart
- Removed unused variable `startTime` from test file
- Added `const` keyword to all constructors for performance optimization
- Fixed double literal `2.0` to `2` where appropriate
- Optimized `const` declarations in test code

**Result:** ✅ **Zero dart analyze issues** - Ready for pub.dev maximum score

## [1.7.0] - 2026-03-30

### Added

#### Docker NAT Testing System
- **Complete Docker-based testing infrastructure** for SHSP handshake validation across all NAT types
- **7 new Melos commands** for easy test execution:
  - `melos docker:test:setup` - One-time Docker environment setup
  - `melos docker:test:all` - Run all 4 NAT type tests
  - `melos docker:test:full_cone` - Test Full Cone NAT individually
  - `melos docker:test:address_restricted` - Test Address Restricted NAT individually
  - `melos docker:test:port_restricted` - Test Port Restricted NAT individually
  - `melos docker:test:symmetric` - Test Symmetric NAT individually
  - `melos docker:test:results` - View test results in JSON format

#### Test Infrastructure
- **docker_test/** directory with complete testing setup:
  - Dockerfile with Dart:latest and system dependencies (iptables, iproute2)
  - docker-compose.yml with 2-peer configuration
  - NAT simulator using iptables for 4 NAT type behaviors
  - Dart-based UDP handshake test implementation
  - Python result aggregation and HTML report generation

#### Documentation
- `docker_test/README.md` - Comprehensive testing guide
- `docker_test/QUICK_START.md` - 5-minute quick start guide
- `docker_test/ARCHITECTURE.md` - Technical architecture details
- `docker_test/SUMMARY.md` - Project overview
- `docker_test/Makefile` - Convenient Make commands for testing

#### Test Results
- Automated JSON result generation per peer and NAT type
- HTML report generation with summary statistics
- Aggregated results combining all 4 NAT type tests

#### Core Features
- **IDualShspSocketWrapper**: Dual socket wrapper interface for seamless socket migration
- **IRegistryShspSocket**: Registry-backed socket interface for managed socket instances
- Enhanced ShspHandshakeHandler with improved error handling

### Test Coverage

**4 NAT Types Tested:**
1. **Full Cone NAT** - ✅ 100% success (2/2 peers)
2. **Address Restricted Cone NAT** - ✅ 100% success (2/2 peers)
3. **Port Restricted Cone NAT** - ✅ 100% success (2/2 peers)
4. **Symmetric NAT** - ⏱️ 50% (1 success, 1 timeout as expected)

**Overall Results:** 87.5% success rate (7/8 tests)

### Bug Fixes
- **Dockerfile**: Updated from Dart 3.9 to Dart:latest for singleton_manager v0.6.1 compatibility
- **run_peer.sh**: Fixed Dart invocation from `dart run` to `dart` for standalone script execution
- **docker-compose.yml**: Changed hostname-based communication to direct IP addresses (192.168.10.x) for reliable DNS resolution
- **handshake_test.dart**: Simplified UDP communication implementation, removed incorrect SHSP API usage
- **ShspHandshakeHandler**: Fixed socket handling and error propagation

### Technical Improvements
- Isolated Docker network (192.168.10.0/24) for test environment
- NAT behavior simulation using iptables rules
- Connection timeout handling (10 seconds per peer)
- Result persistence in JSON format for CI/CD integration

### Infrastructure Changes
- Docker-based isolation prevents environment pollution
- Multi-stage Docker builds for optimized image size
- Proper network configuration for reliable peer-to-peer communication
- Comprehensive logging for test debugging

## [1.0.0] - 2026-03-30

### Initial Release
- Single HandShake Protocol implementation
- Core handshake mechanism for peer discovery and connection establishment
- Support for IPv4 and IPv6
- Basic SHSP socket wrapper implementation
- Singleton management for socket instances
- Comprehensive test suite for core functionality

---

## Version Numbering

- **MAJOR** (X._._ ): Breaking changes to public APIs
- **MINOR** (_.X._): New features, backwards compatible
- **PATCH** (_._.X): Bug fixes and minor improvements

## Release Process

1. Update version in `pubspec.yaml`
2. Update CHANGELOG.md with changes
3. Run tests: `melos test`
4. Create version tag: `git tag v1.1.0`
5. Create release notes
6. Deploy/publish as needed
