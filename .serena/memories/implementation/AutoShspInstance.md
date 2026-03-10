# AutoShspInstance Implementation Summary

## What was implemented
Created `AutoShspInstance` class following Option A from the plan to provide automatic socket management at the instance level, mirroring the pattern established by `AutoShspPeer`.

## Files created
1. **packages/implementations/lib/shsp_instance/auto_shsp_instance.dart**
   - Extends `ShspInstance`
   - Automatically uses `ShspSocketSingleton` for socket management
   - Tracks socket changes and re-registers callbacks on reconnection
   - Does not close the singleton socket on `close()`
   - Provides `create()` static factory method for automatic socket initialization
   - Provides `withSocket()` factory for testing with explicit sockets

2. **packages/tests/test/auto_shsp_instance_test.dart**
   - 10 comprehensive tests covering:
     - Singleton initialization
     - Socket reuse across multiple instances
     - Proper cleanup without closing singleton
     - Multiple instances coexistence
     - Custom address/port parameters
     - Socket reconnection callback handling
     - Test factory usage

## Changes to existing files
- **packages/implementations/lib/shsp_implementations.dart**: Added export for `AutoShspInstance`

## Key features
- **Automatic socket management**: Gets socket from `ShspSocketSingleton` automatically
- **Socket reconnection handling**: Automatically re-registers message callbacks when socket is replaced
- **Shared socket architecture**: Multiple instances can share the same socket singleton
- **Clean separation**: Closing an instance doesn't affect other instances or the global socket

## Test results
✅ All 10 AutoShspInstance tests pass
✅ All AutoShspPeer tests still pass (no regressions)
✅ Barrel export working correctly

## Pattern consistency
Follows the same pattern as `AutoShspPeer` for consistency:
```
ShspPeer      → AutoShspPeer       (peer layer, auto socket)
ShspInstance  → AutoShspInstance   (session layer, auto socket)
```
