# Publication Guide for SHSP Package

> **Note:** As of v1.8.0, SHSP is published as a single unified package. The previous multi-package approach (shsp_types, shsp_interfaces, shsp_implementations) has been consolidated.

This guide explains how to publish the unified SHSP package to pub.dev.

## Pre-Publication Checklist

Before publishing, verify:

- ✅ Version updated in `packages/shsp/pubspec.yaml`
- ✅ CHANGELOG.md updated with new version and changes
- ✅ README.md updated (both root and packages/shsp/README.md)
- ✅ All tests passing: `cd packages/shsp && dart test`
- ✅ Dart analysis clean: `cd packages/shsp && dart analyze`
- ✅ Code formatted: `cd packages/shsp && dart format .`
- ✅ Git tags created for release

## Publishing Process

### 1. Prepare the Release

Create a release branch and tag:

```bash
git checkout -b release/v1.8.0
git tag -a v1.8.0 -m "Release v1.8.0"
```

### 2. Validate the Package

Run a dry-run publication to check for issues:

```bash
cd packages/shsp
dart pub publish --dry-run
```

This will validate:
- pubspec.yaml format
- README.md existence and length
- CHANGELOG.md existence and entries
- LICENSE file existence
- SDK constraints
- Dependencies

### 3. Publish to pub.dev

Execute the publication command:

```bash
cd packages/shsp
dart pub publish
```

This will:
- Prompt for authentication if needed
- Validate the package one final time
- Upload to pub.dev
- Make it available at https://pub.dev/packages/shsp

### 4. Verify Publication

After successful publication:

1. Visit https://pub.dev/packages/shsp
2. Verify version is listed correctly
3. Check that documentation is rendered properly
4. Test installation: `dart pub add shsp:^1.8.0`

### 5. Create Release on GitHub

After pub.dev confirmation:

```bash
git push origin release/v1.8.0
git push origin v1.8.0
```

Create a GitHub release with:
- Version tag
- Release notes from CHANGELOG.md
- Download artifacts (if applicable)

## Package Information

- **Package Name**: `shsp`
- **Repository**: https://github.com/lgualandi/SingleHandShakeProtocolDart
- **Current Version**: 1.8.0
- **License**: LGPL-3.0-only
- **Dart SDK**: >=3.9.4 <4.0.0

## Documentation

The package includes comprehensive documentation:

- `packages/shsp/README.md` - Full API documentation and examples
- `packages/shsp/CHANGELOG.md` - Version history
- `COMPRESSION_CODEC_USAGE.md` - Compression codec details
- Example code in `packages/shsp/example/`

## Troubleshooting

### Publication Fails with Constraint Issues

Ensure `pubspec.yaml` has correct SDK constraints:

```yaml
environment:
  sdk: '>=3.9.4 <4.0.0'
```

### Documentation Rendering Issues

- Check README.md is valid Markdown
- Verify links are correct (use relative paths)
- Ensure code blocks have language specified

### Dependencies Not Found

If a dependency fails to resolve:

1. Run `dart pub get` locally to verify
2. Check that all dependencies are published on pub.dev
3. Update dependency versions if needed

## Version History

| Version | Date | Status |
|---------|------|--------|
| 1.8.0 | 2026-04-20 | Current |
| 1.7.1 | 2026-04-11 | Released |
| 1.7.0 | 2026-03-30 | Released |
