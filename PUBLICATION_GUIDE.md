# Publication Guide for SHSP Packages

This guide explains how to publish the SHSP packages to pub.dev in the correct order.

## Publication Order

The packages must be published in this specific order due to their dependencies:

1. **shsp_types** (no dependencies on other SHSP packages)
2. **shsp_interfaces** (depends on shsp_types)  
3. **shsp_implementations** (depends on both shsp_types and shsp_interfaces)

## Pre-Publication Steps

All packages have been prepared with:
- ✅ Removed `publish_to: none` restrictions
- ✅ Added comprehensive README files
- ✅ Created CHANGELOG.md files
- ✅ Added LICENSE files (MIT)
- ✅ Updated descriptions and metadata
- ✅ Standardized SDK constraints
- ✅ Added repository, homepage, and issue tracker links

## Publishing Commands

Execute these commands in order:

### 1. Publish shsp_types
```bash
cd packages/types
dart pub publish
```

### 2. Wait for shsp_types to be available, then publish shsp_interfaces
```bash
cd packages/interfaces  
dart pub publish
```

### 3. Wait for shsp_interfaces to be available, then publish shsp_implementations
```bash
cd packages/implementations
dart pub publish
```

## Validation Commands

Before publishing, validate each package:

```bash
# Validate types
cd packages/types && dart pub publish --dry-run

# Validate interfaces (after types is published)
cd packages/interfaces && dart pub publish --dry-run

# Validate implementations (after interfaces is published)  
cd packages/implementations && dart pub publish --dry-run
```

## Package URLs

After publication, the packages will be available at:
- https://pub.dev/packages/shsp_types
- https://pub.dev/packages/shsp_interfaces  
- https://pub.dev/packages/shsp_implementations

## Notes

- The git warning about modified files can be ignored for initial publication
- Each package includes comprehensive documentation and examples
- All packages follow pub.dev best practices
- Versions are set to 1.0.0 for initial release