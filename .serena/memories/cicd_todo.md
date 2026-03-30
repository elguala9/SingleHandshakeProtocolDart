# GitHub Actions CI/CD Configuration Reminder

## Status
⏳ **NOT YET IMPLEMENTED** - Configuration needed for GitHub Actions

## Required Steps

### 1. Setup Dart SDK
Use `dart-lang/setup-dart@v1` action to install Dart

### 2. Get Dependencies
Run `dart pub get` in both packages:
- `packages/shsp`
- `packages/tests`

### 3. Static Analysis
Run `dart analyze` to catch linting and type errors

### 4. Run Tests
Run `dart test` in `packages/tests` to execute full test suite (399 tests)

## Important Notes

### Handshake Timeout Configuration
The handshake test was previously flaky due to timing issues. Fixed with:
- **Timeout**: 10000ms
- **Interval**: 50ms

These values are set in the handshake test code and should NOT be changed without testing.

### Test Count
- Total: 399 tests
- All tests must pass before merge

## Example Workflow Structure
```yaml
name: CI/CD

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Get dependencies (shsp)
        run: cd packages/shsp && dart pub get
      - name: Get dependencies (tests)
        run: cd packages/tests && dart pub get
      - name: Analyze code
        run: dart analyze
      - name: Run tests
        run: cd packages/tests && dart test
```

## Next Steps
1. Create `.github/workflows/ci.yml` with the steps above
2. Test locally first with: `cd packages/tests && dart test`
3. Verify all 399 tests pass
4. Commit and push to trigger CI/CD
