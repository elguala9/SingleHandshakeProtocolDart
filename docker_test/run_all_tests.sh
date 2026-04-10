#!/bin/bash

# Master test script - runs handshake tests for all NAT types

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_TEST_DIR="${PROJECT_ROOT}/docker_test"
RESULTS_DIR="${DOCKER_TEST_DIR}/results"
NAT_TYPES=("full_cone" "address_restricted" "port_restricted" "symmetric")

echo "========================================="
echo "SHSP Handshake NAT Type Testing"
echo "========================================="
echo "Project: ${PROJECT_ROOT}"
echo "Test Directory: ${DOCKER_TEST_DIR}"
echo "Results Directory: ${RESULTS_DIR}"
echo "========================================="

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Clean previous results
rm -f "${RESULTS_DIR}"/*.json "${RESULTS_DIR}"/*.log

# Test counter
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Run tests for each NAT type
for NAT_TYPE in "${NAT_TYPES[@]}"; do
  echo ""
  echo "========================================="
  echo "Testing NAT Type: ${NAT_TYPE}"
  echo "========================================="

  TEST_COUNT=$((TEST_COUNT + 1))

  # Set environment variable
  export NAT_TYPE="${NAT_TYPE}"

  # Start containers
  echo "[TEST] Starting Docker containers..."
  cd "${DOCKER_TEST_DIR}"
  docker-compose up -d --remove-orphans 2>&1 | tee -a "${RESULTS_DIR}/docker_${NAT_TYPE}.log"

  # Wait for peers to complete
  echo "[TEST] Waiting for peers to complete handshake..."
  sleep 15

  # Check if results files were created
  if [ -f "${RESULTS_DIR}/peer1_results.json" ] && [ -f "${RESULTS_DIR}/peer2_results.json" ]; then
    echo "[TEST] ✓ Results files created"
    PASSED_COUNT=$((PASSED_COUNT + 1))

    # Parse results
    echo "[TEST] Analyzing results..."
    peer1_status=$(jq -r '.results[0].status' "${RESULTS_DIR}/peer1_results.json" 2>/dev/null || echo "PARSE_ERROR")
    peer2_status=$(jq -r '.results[0].status' "${RESULTS_DIR}/peer2_results.json" 2>/dev/null || echo "PARSE_ERROR")

    echo "[TEST] Peer1 Status: ${peer1_status}"
    echo "[TEST] Peer2 Status: ${peer2_status}"

    # Move results to NAT-type specific files
    mv "${RESULTS_DIR}/peer1_results.json" "${RESULTS_DIR}/peer1_${NAT_TYPE}_results.json"
    mv "${RESULTS_DIR}/peer2_results.json" "${RESULTS_DIR}/peer2_${NAT_TYPE}_results.json"

  else
    echo "[TEST] ✗ Results files not found"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi

  # Stop containers
  echo "[TEST] Stopping Docker containers..."
  docker-compose down 2>&1 | tee -a "${RESULTS_DIR}/docker_${NAT_TYPE}.log"

  # Clean up output logs
  rm -f "${RESULTS_DIR}"/peer*_output.log

  echo "[TEST] Completed: ${NAT_TYPE}"
done

# Generate summary report
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total Tests: ${TEST_COUNT}"
echo "Passed: ${PASSED_COUNT}"
echo "Failed: ${FAILED_COUNT}"
echo "========================================="

# Aggregate results into a single JSON file
echo "[SUMMARY] Creating aggregated results..."
python3 "${DOCKER_TEST_DIR}/scripts/aggregate_results.py" "${RESULTS_DIR}"

echo "[SUMMARY] Results saved to: ${RESULTS_DIR}"
echo "[SUMMARY] View results with: jq . ${RESULTS_DIR}/aggregate_results.json"

# Display results
if [ -f "${RESULTS_DIR}/aggregate_results.json" ]; then
  echo ""
  echo "========================================="
  echo "Aggregated Results:"
  echo "========================================="
  cat "${RESULTS_DIR}/aggregate_results.json" | jq .
fi

exit 0
