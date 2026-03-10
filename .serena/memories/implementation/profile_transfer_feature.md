# ShspInstance Profile Transfer Implementation

## Summary
Implemented the ability to extract callback listeners and configuration from a ShspInstance and apply them to a new instance for reconnection scenarios (e.g., UDP reconnection with new socket).

## Changes Made

### 1. New Type: `ShspInstanceProfile` 
- Created `packages/types/lib/src/instance_profile.dart`
- Immutable class capturing listeners and keepAliveSeconds configuration
- Exports two typedef aliases:
  - `OnVoidListener = CallbackWithReturn<void, void>`
  - `OnPeerListener = CallbackWithReturn<PeerInfo, void>`

### 2. ShspInstance Methods
- **`extractProfile(): ShspInstanceProfile`** - Extracts all registered listeners from CallbackHandler.map
  - Located in `packages/implementations/lib/shsp_instance/shsp_instance.dart`
  - Accesses listeners via `handler.map.getByIndex(i)` in a loop
  - Does NOT include connection state (_handshake, _open, _closing)

- **`ShspInstance.withProfile({...})`** - Factory constructor
  - Creates new instance with profile's keepAliveSeconds
  - Registers all extracted listeners via `handler.register(cb)`
  - Connection state starts fresh (as required for UDP reconnection)

### 3. Factory Support
- Added `ShspInstanceFactory.createWithProfile(...)` in `packages/implementations/lib/factory/shsp_factories.dart`

### 4. Interface Update
- Added `ShspInstanceProfile extractProfile()` method to `IShspInstance` interface
- Required import of `ShspInstanceProfile` in `packages/interfaces/lib/src/i_shsp_instance.dart`

### 5. Test Coverage
- Created comprehensive test suite in `packages/tests/test/shsp_instance_profile_test.dart`
- 7 test cases covering:
  - Profile extraction with multiple listener types
  - Configuration (keepAliveSeconds) preservation
  - Listener restoration to new instance
  - Multiple listener handling
  - Listener unregistration on restored instance
  - Connection state isolation (not transferred)
  - Profile reuse across instances

## Verification
- All 312 tests pass (7 new + 305 existing)
- No breaking changes - all modifications are additive
- Connection handshake correctly redone on new instance
- Listener identity preserved for unregister() operations
