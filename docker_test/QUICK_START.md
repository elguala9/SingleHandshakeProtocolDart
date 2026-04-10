# Quick Start Guide - SHSP NAT Testing

## TL;DR - Run All Tests

```bash
cd docker_test
bash setup.sh          # One-time setup
bash run_all_tests.sh  # Run all tests
```

Results will be in `docker_test/results/`:
- `aggregate_results.json` - JSON summary of all test results
- `report.html` - Visual HTML report
- `peer1_<nat>_results.json` - Peer 1 results for each NAT type
- `peer2_<nat>_results.json` - Peer 2 results for each NAT type

## Using Make (Recommended)

```bash
cd docker_test
make setup              # First time setup
make test-full         # Run all NAT type tests
make results           # View JSON results
make report            # Open HTML report in browser
```

## Test Individual NAT Types

```bash
cd docker_test

# Test specific NAT type
make test-full_cone              # Full Cone NAT
make test-address_restricted     # Address Restricted
make test-port_restricted        # Port Restricted
make test-symmetric              # Symmetric NAT
```

Or without Make:

```bash
cd docker_test
export NAT_TYPE=full_cone
docker-compose up
```

## Interpreting Results

### Expected Results:

| NAT Type | Expected | Why |
|----------|----------|-----|
| Full Cone | ✅ SUCCESS | Any external address can reach peer |
| Address Restricted | ⚠️ TIMEOUT* | Only packets from specific address can reach |
| Port Restricted | ⚠️ TIMEOUT* | Only packets from specific address:port can reach |
| Symmetric | ❌ TIMEOUT | Cannot establish direct P2P connection without relay |

*May show SUCCESS if relay/STUN is implemented

### Viewing Results:

JSON format:
```bash
cat docker_test/results/aggregate_results.json | jq .
```

HTML report:
```bash
open docker_test/results/report.html
```

Individual peer results:
```bash
jq . docker_test/results/peer1_full_cone_results.json
```

## Troubleshooting

### Docker Issues

```bash
# Check if Docker is running
docker ps

# View container logs
docker logs shsp_peer1
docker logs shsp_peer2

# Check network connectivity
docker-compose exec peer1 ping peer2
```

### No Results Generated

```bash
# Check if containers exited
docker-compose ps

# View full logs
docker-compose logs
```

### Python Script Errors

```bash
# Install required packages
python3 -m pip install --upgrade pip
```

## Files Generated

```
docker_test/
├── results/
│   ├── aggregate_results.json      # Summary of all tests
│   ├── report.html                 # Visual report
│   ├── peer1_full_cone_results.json
│   ├── peer2_full_cone_results.json
│   ├── peer1_address_restricted_results.json
│   ├── peer2_address_restricted_results.json
│   ├── peer1_port_restricted_results.json
│   ├── peer2_port_restricted_results.json
│   ├── peer1_symmetric_results.json
│   ├── peer2_symmetric_results.json
│   ├── docker_*.log                # Docker compose logs
│   └── build.log                   # Build logs
```

## Performance

- Full test suite (4 NAT types): ~1 minute
- Single NAT type: ~15 seconds
- Results stored in JSON format for easy parsing

## Next Steps

1. **Analyze Results**: Open `aggregate_results.json` to see detailed results
2. **View Report**: Open `report.html` in browser for visualization
3. **Extend Tests**: Modify `scripts/handshake_test.dart` for additional tests
4. **Integration**: Use `aggregate_results.json` in CI/CD pipeline

## Clean Up

```bash
# Stop containers and remove results
make clean

# Or manually
docker-compose down
rm -rf docker_test/results/
```

## More Information

See [README.md](README.md) for detailed documentation.
