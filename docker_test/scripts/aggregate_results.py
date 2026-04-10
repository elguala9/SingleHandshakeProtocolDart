#!/usr/bin/env python3

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

def aggregate_results(results_dir):
    """Aggregate all test results into a single JSON file"""

    results_path = Path(results_dir)

    if not results_path.exists():
        print(f"Results directory not found: {results_dir}")
        return

    # Find all result files
    result_files = sorted(results_path.glob("*_results.json"))

    if not result_files:
        print(f"No result files found in {results_dir}")
        return

    # Aggregate results by NAT type
    nat_results = defaultdict(lambda: {
        'peers': [],
        'status': 'UNKNOWN',
        'handshake_success': False,
        'duration_ms': 0,
    })

    all_tests = {
        'test_suite': 'SHSP Handshake NAT Type Testing',
        'timestamp': datetime.now().isoformat(),
        'total_nat_types': 0,
        'nat_types': {},
        'summary': {
            'total_tests': 0,
            'successful': 0,
            'failed': 0,
            'timeout': 0,
            'error': 0,
        }
    }

    # Parse each result file
    for result_file in result_files:
        try:
            with open(result_file, 'r') as f:
                data = json.load(f)

            # Extract NAT type from filename (e.g., peer1_full_cone_results.json)
            filename = result_file.name
            parts = filename.replace('_results.json', '').split('_')

            # Determine NAT type
            nat_type = '_'.join(parts[1:]) if len(parts) > 1 else 'unknown'

            # Get peer ID
            peer_id = data.get('peerId', 'unknown')

            # Get test results
            results = data.get('results', [])

            for result in results:
                status = result.get('status', 'UNKNOWN')

                # Update NAT type results
                nat_results[nat_type]['peers'].append({
                    'peer_id': peer_id,
                    'status': status,
                    'duration_ms': result.get('duration'),
                    'error': result.get('errorMessage'),
                    'handshake_data': result.get('handshakeData'),
                    'start_time': result.get('startTime'),
                    'end_time': result.get('endTime'),
                })

                # Update summary
                all_tests['summary']['total_tests'] += 1

                if status == 'SUCCESS':
                    all_tests['summary']['successful'] += 1
                    nat_results[nat_type]['handshake_success'] = True
                    nat_results[nat_type]['status'] = 'SUCCESS'
                elif status == 'TIMEOUT':
                    all_tests['summary']['timeout'] += 1
                    nat_results[nat_type]['status'] = 'TIMEOUT'
                elif status == 'ERROR':
                    all_tests['summary']['error'] += 1
                    if nat_results[nat_type]['status'] != 'SUCCESS':
                        nat_results[nat_type]['status'] = 'ERROR'
                else:
                    all_tests['summary']['failed'] += 1
                    if nat_results[nat_type]['status'] != 'SUCCESS' and nat_results[nat_type]['status'] != 'ERROR':
                        nat_results[nat_type]['status'] = 'FAILED'

                # Calculate duration
                if result.get('duration'):
                    nat_results[nat_type]['duration_ms'] += result.get('duration', 0)

        except json.JSONDecodeError as e:
            print(f"Warning: Failed to parse {result_file}: {e}")
        except Exception as e:
            print(f"Warning: Error processing {result_file}: {e}")

    # Convert defaultdict to regular dict
    all_tests['nat_types'] = dict(nat_results)
    all_tests['total_nat_types'] = len(nat_results)

    # Add success rate
    total_tests = all_tests['summary']['total_tests']
    if total_tests > 0:
        all_tests['summary']['success_rate'] = f"{(all_tests['summary']['successful'] / total_tests) * 100:.1f}%"

    # Add test details per NAT type
    for nat_type, data in all_tests['nat_types'].items():
        peer_count = len(data['peers'])
        successful_peers = sum(1 for p in data['peers'] if p['status'] == 'SUCCESS')

        data['peer_count'] = peer_count
        data['successful_peers'] = successful_peers

        if peer_count > 0:
            data['success_percentage'] = f"{(successful_peers / peer_count) * 100:.1f}%"

        # Determine expected vs actual for each NAT type
        if nat_type == 'symmetric':
            data['expected_result'] = 'TIMEOUT (Symmetric NAT cannot establish direct connections)'
        else:
            data['expected_result'] = 'SUCCESS'

    # Save aggregated results
    output_file = results_path / 'aggregate_results.json'
    with open(output_file, 'w') as f:
        json.dump(all_tests, f, indent=2)

    print(f"Aggregated results saved to: {output_file}")

    # Print summary
    print("\n" + "="*50)
    print("Test Summary")
    print("="*50)
    for nat_type, data in sorted(all_tests['nat_types'].items()):
        print(f"\n{nat_type.upper()}")
        print(f"  Status: {data['status']}")
        print(f"  Peers: {data['successful_peers']}/{data['peer_count']} successful")
        print(f"  Expected: {data['expected_result']}")
        if data['duration_ms'] > 0:
            print(f"  Duration: {data['duration_ms']}ms")

    print("\n" + "="*50)
    print("Overall Summary")
    print("="*50)
    print(f"Total Tests Run: {all_tests['summary']['total_tests']}")
    print(f"Successful: {all_tests['summary']['successful']}")
    print(f"Timeout: {all_tests['summary']['timeout']}")
    print(f"Error: {all_tests['summary']['error']}")
    if 'success_rate' in all_tests['summary']:
        print(f"Success Rate: {all_tests['summary']['success_rate']}")

    # Save HTML report
    generate_html_report(all_tests, results_path)

def generate_html_report(data, results_path):
    """Generate an HTML report of the results"""

    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>SHSP NAT Testing Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1 {{ color: #333; }}
        table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
        tr:nth-child(even) {{ background-color: #f2f2f2; }}
        .success {{ color: green; font-weight: bold; }}
        .failure {{ color: red; font-weight: bold; }}
        .timeout {{ color: orange; font-weight: bold; }}
        .summary {{ background-color: #f9f9f9; padding: 15px; border-radius: 5px; }}
    </style>
</head>
<body>
    <h1>SHSP Handshake NAT Type Testing Report</h1>
    <p>Generated: {data['timestamp']}</p>

    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Tests:</strong> {data['summary']['total_tests']}</p>
        <p><strong>Successful:</strong> <span class="success">{data['summary']['successful']}</span></p>
        <p><strong>Timeout:</strong> <span class="timeout">{data['summary']['timeout']}</span></p>
        <p><strong>Error:</strong> <span class="failure">{data['summary']['error']}</span></p>
        <p><strong>Success Rate:</strong> {data['summary'].get('success_rate', 'N/A')}</p>
    </div>

    <h2>Results by NAT Type</h2>
    <table>
        <tr>
            <th>NAT Type</th>
            <th>Status</th>
            <th>Peers</th>
            <th>Expected Result</th>
            <th>Duration (ms)</th>
        </tr>
"""

    for nat_type, nat_data in sorted(data['nat_types'].items()):
        status_class = 'success' if nat_data['status'] == 'SUCCESS' else 'failure' if nat_data['status'] == 'ERROR' else 'timeout'
        html_content += f"""        <tr>
            <td><strong>{nat_type}</strong></td>
            <td><span class="{status_class}">{nat_data['status']}</span></td>
            <td>{nat_data['successful_peers']}/{nat_data['peer_count']}</td>
            <td>{nat_data['expected_result']}</td>
            <td>{nat_data.get('duration_ms', 0)}</td>
        </tr>
"""

    html_content += """    </table>

    <h2>Peer Details</h2>
"""

    for nat_type, nat_data in sorted(data['nat_types'].items()):
        html_content += f"""    <h3>{nat_type.upper()}</h3>
    <table>
        <tr>
            <th>Peer ID</th>
            <th>Status</th>
            <th>Error</th>
            <th>Duration (ms)</th>
        </tr>
"""
        for peer in nat_data['peers']:
            status_class = 'success' if peer['status'] == 'SUCCESS' else 'failure' if peer['status'] == 'ERROR' else 'timeout'
            html_content += f"""        <tr>
            <td>{peer['peer_id']}</td>
            <td><span class="{status_class}">{peer['status']}</span></td>
            <td>{peer['error'] or 'N/A'}</td>
            <td>{peer['duration_ms'] or 'N/A'}</td>
        </tr>
"""
        html_content += """    </table>
"""

    html_content += """</body>
</html>
"""

    output_file = results_path / 'report.html'
    with open(output_file, 'w') as f:
        f.write(html_content)

    print(f"HTML report saved to: {output_file}")

if __name__ == '__main__':
    results_dir = sys.argv[1] if len(sys.argv) > 1 else './results'
    aggregate_results(results_dir)
