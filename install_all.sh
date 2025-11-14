#!/bin/bash

echo "Installing dependencies for all packages..."

cd packages/types
echo "Installing types..."
dart pub get

cd ../interfaces
echo "Installing interfaces..."
dart pub get

cd ../implementations
echo "Installing implementations..."
dart pub get

cd ../tests
echo "Installing tests..."
dart pub get

cd ../..
echo "All packages installed successfully!"
