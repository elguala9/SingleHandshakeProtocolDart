#!/bin/bash

set -e

echo "================================"
echo "Starting SHSP Peer: ${PEER_ID}"
echo "NAT Type: ${NAT_TYPE}"
echo "Port: ${PEER_PORT}"
echo "Remote: ${REMOTE_PEER_HOST}:${REMOTE_PEER_PORT}"
echo "================================"

# Create results directory
mkdir -p /app/results

# Wait for network to be ready
sleep 2

# Get current IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "[PEER] Current IP: ${CURRENT_IP}"

# Configure NAT if needed
if [ ! -z "$NAT_TYPE" ]; then
  bash /app/test_scripts/nat_simulator.sh "$NAT_TYPE" "$PEER_ID" "$CURRENT_IP" "172.17.0.100" "$PEER_PORT"
fi

# Execute the handshake test
echo "[PEER] Starting handshake test..."

cd /app

# Create and run the test Dart script
dart /app/test_scripts/handshake_test.dart \
  --peer-id "$PEER_ID" \
  --peer-port "$PEER_PORT" \
  --remote-host "$REMOTE_PEER_HOST" \
  --remote-port "$REMOTE_PEER_PORT" \
  --nat-type "$NAT_TYPE" \
  --local-ip "$CURRENT_IP" \
  --results-dir "/app/results" \
  2>&1 | tee "/app/results/${PEER_ID}_output.log"

echo "[PEER] Handshake test complete"

# Keep container running to prevent immediate exit
sleep 5
