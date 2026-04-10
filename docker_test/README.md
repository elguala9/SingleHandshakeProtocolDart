# SHSP Handshake NAT Type Testing

Comprehensive Docker-based testing suite for Single HandShake Protocol (SHSP) with NAT type simulation.

## Overview

This test suite validates SHSP handshake functionality across all four NAT types:

1. **Full Cone NAT** - External packets from ANY address/port can reach the internal IP/port
2. **Address Restricted Cone NAT** - External packets from a specific source address (any port) can reach internal IP/port
3. **Port Restricted Cone NAT** - External packets from a specific source address and port can reach internal IP/port
4. **Symmetric NAT** - Different external ports for different destination addresses (typically fails direct connection)

## Structure

```
docker_test/
├── Dockerfile                 # Container image for SHSP peer
├── docker-compose.yml        # Docker Compose configuration for peer orchestration
├── run_all_tests.sh         # Master test script (runs all NAT types)
├── README.md                 # This file
├── scripts/
│   ├── run_peer.sh          # Peer startup script
│   ├── nat_simulator.sh      # NAT type simulation using iptables/tc
│   ├── handshake_test.dart   # Dart application for handshake testing
│   └── aggregate_results.py  # Results aggregation and reporting
└── results/                  # Test results directory (generated)
    ├── peer1_<nat>_results.json
    ├── peer2_<nat>_results.json
    ├── aggregate_results.json
    └── report.html
```

## Prerequisites

- Docker and Docker Compose
- Bash shell
- Python 3.x
- jq (for JSON processing)
- Dart SDK 3.9+

## Quick Start

### Run All NAT Type Tests

```bash
cd docker_test
bash run_all_tests.sh
```

This will:
1. Test all four NAT types sequentially
2. Generate individual result files for each NAT type
3. Create an aggregated JSON report
4. Generate an HTML report

### Run Specific NAT Type

```bash
cd docker_test
export NAT_TYPE=full_cone
docker-compose up
```

Set `NAT_TYPE` to one of:
- `full_cone`
- `address_restricted`
- `port_restricted`
- `symmetric`

## Results

### JSON Results Format

Each test generates results in this format:

```json
{
  "test": "SHSP Handshake NAT Test",
  "timestamp": "2026-04-10T12:00:00.000Z",
  "peerId": "peer1",
  "natType": "full_cone",
  "results": [
    {
      "peerId": "peer1",
      "natType": "full_cone",
      "status": "SUCCESS|TIMEOUT|ERROR|FATAL_ERROR",
      "errorMessage": null,
      "startTime": "2026-04-10T12:00:00.000Z",
      "endTime": "2026-04-10T12:00:05.000Z",
      "duration": 5000,
      "handshakeData": {
        "sent": {...},
        "received": {...},
        "rtt": 123
      }
    }
  ]
}
```

### Aggregated Results

View the aggregated results:

```bash
jq . docker_test/results/aggregate_results.json
```

### HTML Report

Open the generated HTML report in a browser:

```bash
open docker_test/results/report.html
```

## Expected Results

| NAT Type | Expected Outcome | Notes |
|----------|-----------------|-------|
| Full Cone | SUCCESS | Can establish direct connection in both directions |
| Address Restricted | SUCCESS* | May work with relay/STUN servers |
| Port Restricted | SUCCESS* | May work with relay/STUN servers |
| Symmetric | TIMEOUT | Cannot establish direct connection (needs relay) |

*Success depends on NAT behavior implementation

## Test Execution Flow

1. **Setup Phase**
   - Build Docker images
   - Create network bridge
   - Prepare results directory

2. **NAT Configuration**
   - For each NAT type, configure iptables rules
   - Simulate packet filtering/translation behavior

3. **Handshake Test**
   - Peer1 sends handshake packet with local IP info
   - Peer2 receives and responds
   - Exchange IP address information
   - Validate connection establishment

4. **Result Collection**
   - Save individual peer results as JSON
   - Aggregate results across NAT types
   - Generate reports (JSON + HTML)

5. **Cleanup**
   - Stop and remove containers
   - Preserve result files

## Troubleshooting

### No Result Files Generated

Check container logs:
```bash
docker logs shsp_peer1
docker logs shsp_peer2
```

### NAT Rules Not Applied

Verify iptables rules:
```bash
docker exec shsp_peer1 iptables -t nat -L -n -v
```

### Network Connectivity Issues

Test basic connectivity:
```bash
docker-compose exec peer1 ping peer2
docker-compose exec peer1 nc -u -z peer2 5001
```

### Python Script Errors

Ensure Python 3 and jq are installed:
```bash
python3 --version
jq --version
```

## Performance Considerations

- Each test takes ~15 seconds (handshake timeout)
- Full test suite (4 NAT types) takes ~60 seconds
- Results are stored in `docker_test/results/`

## Advanced Usage

### Custom Test Parameters

Edit `docker-compose.yml` to change:
- Peer IP addresses
- Port numbers
- Timeout values
- Network configuration

### Extend NAT Simulator

Add custom NAT types to `scripts/nat_simulator.sh`:

```bash
custom_nat)
  echo "[NAT] Custom NAT configuration"
  # Add custom iptables rules here
  ;;
```

### Integration with CI/CD

Run in CI pipeline:

```bash
cd docker_test
bash run_all_tests.sh
test -f results/aggregate_results.json && echo "Tests passed" || echo "Tests failed"
```

## Development

### Adding New Tests

1. Add test logic to `scripts/handshake_test.dart`
2. Extend result parsing in `scripts/aggregate_results.py`
3. Update expected results table in documentation

### Debugging

Enable verbose logging:

```bash
# In docker-compose.yml, add:
environment:
  DEBUG: "true"
  VERBOSE: "true"
```

View real-time logs:
```bash
docker-compose logs -f
```

## License

Part of the Single HandShake Protocol (SHSP) project.

## References

- [STUN Protocol (RFC 3489)](https://tools.ietf.org/html/rfc3489)
- [NAT Behavior Discovery Protocol](https://tools.ietf.org/html/rfc5780)
- [SHSP Documentation](../../README.md)
