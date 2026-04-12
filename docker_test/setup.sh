#!/bin/bash

# Setup script for SHSP NAT Testing

set -e

echo "========================================="
echo "SHSP NAT Testing - Setup"
echo "========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make scripts executable
chmod +x "${SCRIPT_DIR}/run_all_tests.sh"
chmod +x "${SCRIPT_DIR}/scripts/run_peer.sh"
chmod +x "${SCRIPT_DIR}/scripts/nat_simulator.sh"
chmod +x "${SCRIPT_DIR}/scripts/aggregate_results.py"

echo "[SETUP] Scripts made executable"

# Check prerequisites
echo "[SETUP] Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "✗ Docker is not installed. Please install Docker."; exit 1; }
echo "✓ Docker found: $(docker --version)"

command -v docker-compose >/dev/null 2>&1 || { echo "✗ Docker Compose is not installed. Please install Docker Compose."; exit 1; }
echo "✓ Docker Compose found: $(docker-compose --version)"

command -v python3 >/dev/null 2>&1 || { echo "✗ Python 3 is not installed. Please install Python 3."; exit 1; }
echo "✓ Python 3 found: $(python3 --version)"

# Check for jq (optional - used only for results display, not for running tests)
if command -v jq >/dev/null 2>&1; then
    echo "✓ jq found: $(jq --version)"
else
    echo "⚠ jq not found - results display will be limited (tests will still run)"
fi

command -v dart >/dev/null 2>&1 || { echo "✗ Dart SDK is not installed. Please install Dart."; exit 1; }
echo "✓ Dart found: $(dart --version)"

# Create results directory
mkdir -p "${SCRIPT_DIR}/results"
echo "[SETUP] Results directory created"

# Build Docker image
echo "[SETUP] Building Docker image..."
cd "${SCRIPT_DIR}"
docker-compose build --no-cache 2>&1 | tee "${SCRIPT_DIR}/results/build.log"

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To run all tests, execute:"
echo "  bash run_all_tests.sh"
echo ""
echo "To run tests for a specific NAT type:"
echo "  export NAT_TYPE=full_cone"
echo "  docker-compose up"
echo ""
echo "For more information, see README.md"
echo ""
