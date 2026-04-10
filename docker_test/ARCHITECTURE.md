# SHSP NAT Testing - Architecture & Design

## Overview

The SHSP NAT Testing Suite is a Docker-based system that validates Single HandShake Protocol handshake functionality across four different NAT types. The architecture is designed to be modular, repeatable, and produce reliable test results in JSON format.

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│ Master Control Script (run_all_tests.sh)           │
│  - Orchestrates tests for all 4 NAT types         │
│  - Manages Docker containers                       │
│  - Collects results                                │
└──────────────────────┬──────────────────────────────┘
                       │
      ┌────────────────┼────────────────┐
      │                │                │
      ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Full Cone    │ │ Address Res. │ │ Port Res.    │
│ NAT Test     │ │ NAT Test     │ │ NAT Test     │
└──────────────┘ └──────────────┘ └──────────────┘
      │                │                │
      └────────────────┼────────────────┘
                       │
      ┌────────────────┼────────────────┐
      │                │                │
      ▼                ▼                ▼
┌──────────────────────────────────────────────────┐
│ Docker Compose Orchestration                     │
│  - Start peer1 and peer2 containers              │
│  - Setup network bridge (192.168.10.0/24)        │
│  - Mount volumes for scripts and results         │
└──────────────────────┬───────────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       │                               │
       ▼                               ▼
┌──────────────────┐         ┌──────────────────┐
│ Peer 1 Container │         │ Peer 2 Container │
│ (192.168.10.10)  │◄───────►│ (192.168.10.20)  │
│                  │  UDP    │                  │
│ - NAT Setup      │  5000   │ - NAT Setup      │
│ - Handshake Test │  ◄───►  │ - Handshake Test │
│ - Result Gen     │  5001   │ - Result Gen     │
└──────────────────┘         └──────────────────┘
       │                               │
       └───────────────┬───────────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
         ▼                           ▼
   peer1_results.json         peer2_results.json
         │                           │
         └─────────────┬─────────────┘
                       │
         ┌─────────────▼──────────────┐
         │ Result Aggregation Script  │
         │ (aggregate_results.py)     │
         └─────────────┬──────────────┘
                       │
         ┌─────────────┴──────────────┐
         │                            │
         ▼                            ▼
aggregate_results.json         report.html
```

## Components

### 1. Master Control Script (`run_all_tests.sh`)

**Purpose**: Orchestrate testing for all NAT types

**Flow**:
1. Create results directory
2. Loop through each NAT type
3. Set `NAT_TYPE` environment variable
4. Start Docker containers with `docker-compose up`
5. Wait for test completion (~15 seconds per NAT type)
6. Check for result files
7. Stop containers
8. Move results to NAT-type specific files
9. Run aggregation script
10. Display summary

### 2. Docker Compose Configuration (`docker-compose.yml`)

**Purpose**: Define and orchestrate peer containers

**Key Components**:
- **Peer 1**: Initiator (192.168.10.10:5000)
- **Peer 2**: Responder (192.168.10.20:5001)
- **Network**: Dedicated bridge network (192.168.10.0/24)
- **Volumes**: Mount scripts and results directory
- **Capabilities**: NET_ADMIN for iptables manipulation

**Environment Variables**:
- `NAT_TYPE`: Type of NAT to simulate
- `PEER_ID`: Identifier for the peer
- `PEER_PORT`: UDP listen port
- `REMOTE_PEER_HOST`: Hostname of remote peer
- `REMOTE_PEER_PORT`: Port of remote peer

### 3. Peer Startup Script (`scripts/run_peer.sh`)

**Purpose**: Initialize peer environment and start test

**Steps**:
1. Create results directory
2. Wait for network to be ready
3. Get current IP address
4. Apply NAT configuration via `nat_simulator.sh`
5. Run Dart test script with appropriate parameters

### 4. NAT Simulator (`scripts/nat_simulator.sh`)

**Purpose**: Configure iptables rules to simulate NAT types

**NAT Type Implementations**:

#### Full Cone NAT
```
- DNAT: Map external port to internal IP:port
- SNAT: Translate source address on outbound packets
- Behavior: Any external packet can reach internal IP:port
```

#### Address Restricted Cone NAT
```
- DNAT: Map external port to internal IP:port (with state tracking)
- Connection tracking: Only ESTABLISHED,RELATED packets
- Block NEW incoming packets from unknown sources
- Behavior: Only packets from connected sources can reach internal IP
```

#### Port Restricted Cone NAT
```
- DNAT: Map external port to internal IP:port (with state tracking)
- Connection tracking: Stricter than address restricted
- Behavior: Only packets from connected source:port can reach internal IP
```

#### Symmetric NAT
```
- SNAT: Map to random port for each destination
- Different external ports for different destination addresses
- Behavior: Difficult for direct P2P connections
```

### 5. Handshake Test (`scripts/handshake_test.dart`)

**Purpose**: Execute handshake protocol test

**Components**:
- `TestResult`: Data class for storing test results
- `ShspHandshakeTest`: Main test orchestrator
- `_waitForResponse()`: Listen for peer response with timeout

**Flow**:
1. Bind UDP socket to local IP:port
2. Create SHSP handshake components (IP, Time, Ownership)
3. Prepare handshake packet with peer metadata
4. Send packet to remote peer
5. Wait for response (10-second timeout)
6. Handle response or timeout
7. Save results to JSON file

**Result Structure**:
```json
{
  "peerId": "peer1",
  "natType": "full_cone",
  "status": "SUCCESS|TIMEOUT|ERROR",
  "handshakeData": {
    "sent": { /* handshake packet */ },
    "received": { /* response packet */ },
    "rtt": 123
  },
  "duration": 5000
}
```

### 6. Results Aggregation (`scripts/aggregate_results.py`)

**Purpose**: Collect and summarize test results

**Process**:
1. Find all `*_results.json` files
2. Parse each result file
3. Group results by NAT type
4. Calculate success rates and statistics
5. Generate JSON summary
6. Generate HTML report

**Output Files**:
- `aggregate_results.json`: Structured JSON summary
- `report.html`: HTML visualization of results

## NAT Type Explanation

### Full Cone NAT
- **Definition**: All traffic from an internal IP/port to any external IP/port is mapped to a single external IP/port
- **Behavior**: External hosts can send packets to internal host
- **Use Case**: Most permissive NAT, usually works for P2P
- **Expected**: ✅ SUCCESS

### Address Restricted Cone NAT
- **Definition**: Like Full Cone, but external hosts can only send packets to internal host if they've already received traffic from internal host
- **Behavior**: Port is restricted by source address
- **Use Case**: Common in residential gateways
- **Expected**: ⚠️ TIMEOUT (without STUN/relay)

### Port Restricted Cone NAT
- **Definition**: Like Address Restricted, but also restricted by source port
- **Behavior**: Port is restricted by source address AND port
- **Use Case**: More restrictive firewalls
- **Expected**: ⚠️ TIMEOUT (without STUN/relay)

### Symmetric NAT
- **Definition**: Each request from an internal IP/port to different external addresses gets a different external port
- **Behavior**: Difficult for P2P communication without relay
- **Use Case**: Enterprise networks, carrier-grade NAT
- **Expected**: ❌ TIMEOUT (always)

## Data Flow

### Peer 1 (Initiator)
```
1. Bind UDP socket to 192.168.10.10:5000
2. Create handshake message with local IP info
3. Send to peer2 (192.168.10.20:5001)
4. Listen for response
5. Record RTT and success status
6. Save results to peer1_<nat>_results.json
```

### Peer 2 (Responder)
```
1. Bind UDP socket to 192.168.10.20:5001
2. Listen for handshake message
3. When received, extract peer info
4. Send response with local IP info
5. Record successful exchange
6. Save results to peer2_<nat>_results.json
```

## Result File Structure

### Individual Peer Results
```json
{
  "test": "SHSP Handshake NAT Test",
  "timestamp": "2026-04-10T12:00:00Z",
  "peerId": "peer1",
  "natType": "full_cone",
  "results": [
    {
      "peerId": "peer1",
      "natType": "full_cone",
      "status": "SUCCESS",
      "duration": 5000,
      "handshakeData": {
        "sent": { /* packet sent */ },
        "received": { /* response */ },
        "rtt": 123
      }
    }
  ]
}
```

### Aggregated Results
```json
{
  "test_suite": "SHSP Handshake NAT Type Testing",
  "timestamp": "2026-04-10T12:05:00Z",
  "nat_types": {
    "full_cone": {
      "status": "SUCCESS",
      "peer_count": 2,
      "successful_peers": 2,
      "success_percentage": "100%",
      "peers": [ /* peer details */ ]
    },
    // ... other NAT types
  },
  "summary": {
    "total_tests": 8,
    "successful": 2,
    "timeout": 4,
    "error": 2
  }
}
```

## Extensibility

### Adding New Tests
1. Modify `scripts/handshake_test.dart` to add test logic
2. Update `aggregate_results.py` to parse new result fields
3. Update documentation

### Adding New NAT Types
1. Add new case to `scripts/nat_simulator.sh`
2. Update `run_all_tests.sh` NAT_TYPES array
3. Document expected behavior

### Custom Result Processing
- Results are in standard JSON format
- Easy to integrate with CI/CD pipelines
- Can be parsed by any JSON tool (jq, Python, etc.)

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Per NAT Type | ~15 seconds |
| Full Suite | ~60 seconds |
| Network Latency | ~1-5ms (Docker) |
| Max Timeout | 10 seconds |
| Result File Size | ~2-5KB |

## Error Handling

### Container Errors
- Automatically logged to `results/docker_<nat>.log`
- Docker Compose exit codes propagated

### Handshake Failures
- `TIMEOUT`: No response within 10 seconds
- `ERROR`: Exception during send/receive
- `FATAL_ERROR`: Unrecoverable error (socket binding, etc.)

### Result Processing
- Invalid JSON files skipped with warning
- Missing result files marked as failed
- Python errors logged and handled gracefully

## Security Considerations

1. **Isolation**: Each test runs in isolated Docker containers
2. **Network**: Dedicated bridge network (not exposed to host)
3. **Capabilities**: Only NET_ADMIN capability required
4. **Data**: No sensitive data collected or stored

## Testing the Tests

To verify the test infrastructure:

```bash
# Test Docker connectivity
docker-compose exec peer1 ping peer2

# Test NAT rules
docker-compose exec peer1 iptables -t nat -L

# Test UDP connectivity
docker-compose exec peer1 nc -u -l 5000

# Test result generation
docker-compose exec peer1 cat /app/results/peer1_results.json
```

## Future Improvements

1. **STUN Integration**: Add STUN server for relay testing
2. **Metrics Collection**: Time, packet loss, latency measurements
3. **Visual Graphs**: Add graph generation for trends
4. **Multi-peer Testing**: Test with more than 2 peers
5. **Stress Testing**: High-volume connection testing
6. **Network Simulation**: Add latency/packet loss simulation

## References

- [RFC 3489 - STUN Protocol](https://tools.ietf.org/html/rfc3489)
- [RFC 5780 - NAT Behavior Discovery](https://tools.ietf.org/html/rfc5780)
- [Docker Documentation](https://docs.docker.com/)
- [iptables Manual](https://linux.die.net/man/8/iptables)
