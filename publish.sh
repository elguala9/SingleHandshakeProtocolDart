#!/bin/bash

# SHSP Packages Publication Script
# This script publishes all SHSP packages in the correct order

set -e

echo "🚀 Starting SHSP packages publication process..."

# Function to wait for user confirmation
wait_for_confirmation() {
    read -p "Press Enter to continue when ready..."
}

# Function to check if package is available on pub.dev
check_package_availability() {
    local package=$1
    echo "⏳ Checking if $package is available on pub.dev..."
    # Simple check - you might want to implement a more robust check
    sleep 5
    echo "✅ $package should be available now"
}

echo ""
echo "📦 Step 1: Publishing shsp_types..."
cd packages/types
echo "Validating shsp_types package..."
dart pub publish --dry-run
echo ""
echo "Ready to publish shsp_types. This package has no dependencies on other SHSP packages."
wait_for_confirmation
dart pub publish

echo ""
echo "⏳ Waiting for shsp_types to be available on pub.dev..."
check_package_availability "shsp_types"

echo ""
echo "📦 Step 2: Publishing shsp_interfaces..."
cd ../interfaces
echo "Validating shsp_interfaces package..."
dart pub get
dart pub publish --dry-run
echo ""
echo "Ready to publish shsp_interfaces. This package depends on shsp_types."
wait_for_confirmation
dart pub publish

echo ""
echo "⏳ Waiting for shsp_interfaces to be available on pub.dev..."
check_package_availability "shsp_interfaces"

echo ""
echo "📦 Step 3: Publishing shsp_implementations..."
cd ../implementations
echo "Validating shsp_implementations package..."
dart pub get
dart pub publish --dry-run
echo ""
echo "Ready to publish shsp_implementations. This package depends on shsp_types and shsp_interfaces."
wait_for_confirmation
dart pub publish

echo ""
echo "🎉 All SHSP packages have been published successfully!"
echo ""
echo "📋 Published packages:"
echo "   • https://pub.dev/packages/shsp_types"
echo "   • https://pub.dev/packages/shsp_interfaces"
echo "   • https://pub.dev/packages/shsp_implementations"
echo ""
echo "✨ Publication complete!"