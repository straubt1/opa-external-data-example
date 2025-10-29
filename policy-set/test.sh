#!/bin/bash

# OPA Policy Testing Script
# This script provides quick commands to test the OPA policy locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if OPA is available
if command -v opa &> /dev/null; then
    OPA_CMD="opa"
elif [ -f "$HOME/bin/opa" ]; then
    OPA_CMD="$HOME/bin/opa"
elif [ -f ~/bin/opa ]; then
    OPA_CMD=~/bin/opa
else
    echo "Error: OPA not found. Please install OPA first."
    echo "Run: curl -L -o $HOME/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.61.0/opa_darwin_amd64 && chmod +x $HOME/bin/opa"
    exit 1
fi

echo "========================================="
echo "OPA Policy Testing"
echo "========================================="
echo ""

# Function to run tests
run_tests() {
    echo "Running unit tests..."
    $OPA_CMD test policies/ -v
    echo ""
}

# Function to test with mock data
test_mock_passing() {
    echo "Testing with mock data (passing scenario)..."
    $OPA_CMD eval \
        --data policies/external_data_policy.rego \
        --data test-data/mock-external-data.json \
        --input test-data/passing-input.json \
        --format pretty \
        'data.terraform.policies.external_data_policy.policy_result'
    echo ""
}

test_mock_failing() {
    echo "Testing with mock data (failing scenario)..."
    $OPA_CMD eval \
        --data policies/external_data_policy.rego \
        --data test-data/mock-external-data.json \
        --input test-data/failing-input.json \
        --format pretty \
        'data.terraform.policies.external_data_policy.policy_result'
    echo ""
}

# Function to test with live S3 data
test_live_passing() {
    echo "Testing with live S3 data (passing scenario)..."
    $OPA_CMD eval \
        --data policies/external_data_policy.rego \
        --input test-data/passing-input.json \
        --format pretty \
        'data.terraform.policies.external_data_policy.policy_result'
    echo ""
}

test_live_failing() {
    echo "Testing with live S3 data (failing scenario)..."
    $OPA_CMD eval \
        --data policies/external_data_policy.rego \
        --input test-data/failing-input.json \
        --format pretty \
        'data.terraform.policies.external_data_policy.policy_result'
    echo ""
}

# Function to show external data
show_external_data() {
    echo "Fetching external data from S3..."
    $OPA_CMD eval \
        --data policies/external_data_policy.rego \
        --format pretty \
        'data.terraform.policies.external_data_policy.external_data'
    echo ""
}

# Main menu
case "${1:-all}" in
    test)
        run_tests
        ;;
    mock-pass)
        test_mock_passing
        ;;
    mock-fail)
        test_mock_failing
        ;;
    live-pass)
        test_live_passing
        ;;
    live-fail)
        test_live_failing
        ;;
    show-data)
        show_external_data
        ;;
    all)
        run_tests
        test_mock_passing
        test_mock_failing
        test_live_passing
        test_live_failing
        show_external_data
        ;;
    *)
        echo "Usage: $0 [test|mock-pass|mock-fail|live-pass|live-fail|show-data|all]"
        echo ""
        echo "Commands:"
        echo "  test       - Run unit tests"
        echo "  mock-pass  - Test passing scenario with mock data"
        echo "  mock-fail  - Test failing scenario with mock data"
        echo "  live-pass  - Test passing scenario with live S3 data"
        echo "  live-fail  - Test failing scenario with live S3 data"
        echo "  show-data  - Display external data from S3"
        echo "  all        - Run all tests (default)"
        exit 1
        ;;
esac

echo "========================================="
echo "Testing complete!"
echo "========================================="
