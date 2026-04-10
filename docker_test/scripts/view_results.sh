#!/bin/bash

# Results viewer script

RESULTS_DIR="${1:-.}/docker_test/results"

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Results directory not found: $RESULTS_DIR"
    echo "Run tests first with: bash run_all_tests.sh"
    exit 1
fi

echo "========================================="
echo "SHSP NAT Testing Results"
echo "========================================="
echo ""

# Check if aggregate results exist
if [ -f "$RESULTS_DIR/aggregate_results.json" ]; then
    echo "=== SUMMARY ==="
    jq '.summary' "$RESULTS_DIR/aggregate_results.json"

    echo ""
    echo "=== NAT TYPE RESULTS ==="
    jq '.nat_types | to_entries[] | "\(.key): \(.value.status) - \(.value.successful_peers)/\(.value.peer_count) peers"' "$RESULTS_DIR/aggregate_results.json"

    echo ""
    echo "=== DETAILED RESULTS BY NAT TYPE ==="
    for file in "$RESULTS_DIR"/peer*_results.json; do
        if [ -f "$file" ]; then
            echo ""
            echo "File: $(basename "$file")"
            jq '.' "$file"
        fi
    done

    echo ""
    echo "========================================="
    echo "Results saved in: $RESULTS_DIR"
    echo "View HTML report: open $RESULTS_DIR/report.html"
    echo "========================================="

else
    echo "No results found in: $RESULTS_DIR"
    echo ""
    echo "Available files:"
    ls -la "$RESULTS_DIR"/ 2>/dev/null || echo "Directory is empty"
fi
