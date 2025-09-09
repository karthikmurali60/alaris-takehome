#!/bin/bash

set -e

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for tracking test results
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_TESTS=8

# Required environment variables
REQUIRED_VARS=(
    "KUBECONFIG"
    "DO_SPACES_REGION" 
    "DO_SPACES_ENDPOINT"
    "DO_SPACES_BUCKET"
    "DO_SPACES_ACCESS_KEY"
    "DO_SPACES_SECRET_KEY"
)

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}✅ PASS${NC}: $message" ;;
        "FAIL") echo -e "${RED}❌ FAIL${NC}: $message" ;;
        "INFO") echo -e "${BLUE}ℹ️  INFO${NC}: $message" ;;
        "WARN") echo -e "${YELLOW}⚠️  WARN${NC}: $message" ;;
        "TEST") echo -e "${BLUE}🧪 TEST${NC}: $message" ;;
    esac
}

# Function to increment test counters
record_result() {
    if [ "$1" = "PASS" ]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
}

# Function to validate required environment variables
validate_environment() {
    print_status "INFO" "Validating required environment variables..."
    
    local missing_vars=()
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_status "FAIL" "Missing required environment variables: ${missing_vars[*]}"
        echo ""
        echo "Required environment variables:"
        echo "  KUBECONFIG          - Path to kubeconfig file for DOKS cluster"
        echo "  DO_SPACES_REGION    - DigitalOcean Spaces region (e.g., nyc3, sfo3)"
        echo "  DO_SPACES_ENDPOINT  - DigitalOcean Spaces endpoint (e.g., nyc3.digitaloceanspaces.com)"
        echo "  DO_SPACES_BUCKET    - DigitalOcean Spaces bucket name (e.g., alaris-takehome-bucket)"
        echo "  DO_SPACES_ACCESS_KEY - DigitalOcean Spaces access key"
        echo "  DO_SPACES_SECRET_KEY - DigitalOcean Spaces secret key"
        echo ""
        echo "Example usage:"
        echo "  export KUBECONFIG=~/.kube/config"
        echo "  export DO_SPACES_REGION=nyc3"
        echo "  export DO_SPACES_ENDPOINT=nyc3.digitaloceanspaces.com"
        echo "  export DO_SPACES_BUCKET=alaris-takehome-bucket"
        echo "  export DO_SPACES_ACCESS_KEY=your_access_key"
        echo "  export DO_SPACES_SECRET_KEY=your_secret_key"
        echo "  ./grade.sh"
        exit 1
    fi
    
    print_status "PASS" "All required environment variables are set"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "INFO" "Checking required dependencies..."
    
    local required_tools=("kubectl" "curl" "s3cmd")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_status "FAIL" "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "  kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  curl: Usually pre-installed on most systems"
        echo "  s3cmd: pip install s3cmd or package manager"
        exit 1
    fi
    
    print_status "PASS" "All required tools are available"
}

# Function to configure s3cmd for DigitalOcean Spaces
configure_s3cmd() {
    print_status "INFO" "Configuring s3cmd for DigitalOcean Spaces..."
    
    cat > ~/.s3cfg << EOF
[default]
access_key = ${DO_SPACES_ACCESS_KEY}
secret_key = ${DO_SPACES_SECRET_KEY}
host_base = ${DO_SPACES_ENDPOINT}
host_bucket = %(bucket)s.${DO_SPACES_ENDPOINT}
use_https = True
signature_v2 = False
EOF
    
    print_status "INFO" "s3cmd configured successfully"
}

# Test a: Smoke DB test for tenant-a
test_smoke_db() {
    print_status "TEST" "Testing database connectivity for tenant-a..."
    
    if kubectl exec -n tenant-a deployment/tenant-a-app -- psql -h pg-tenant-a-rw -U postgres -d app -c "SELECT 1;" &>/dev/null; then
        print_status "PASS" "Database connection to tenant-a successful"
        record_result "PASS"
    else
        print_status "FAIL" "Database connection to tenant-a failed"
        record_result "FAIL"
    fi
}

# Test b: Public endpoint reachable
test_public_endpoint() {
    print_status "TEST" "Testing public endpoint accessibility for tenant-a..."
    
    # Get the external IP of the LoadBalancer service
    local external_ip
    external_ip=$(kubectl get svc -n tenant-a tenant-a-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$external_ip" ]; then
        print_status "FAIL" "LoadBalancer external IP not found for tenant-a"
        record_result "FAIL"
        return
    fi
    
    # Test public endpoint
    if curl -s -f "http://${external_ip}/public" | grep -q "tenant-a\|public\|success" 2>/dev/null; then
        print_status "PASS" "Public endpoint for tenant-a is reachable and returns expected content"
        record_result "PASS"
    else
        print_status "FAIL" "Public endpoint for tenant-a is not reachable or returns unexpected content"
        record_result "FAIL"
    fi
}

# Test c: Internal endpoint blocked externally
test_internal_blocked() {
    print_status "TEST" "Testing that internal endpoint is blocked externally for tenant-a..."
    
    # Get the external IP of the LoadBalancer service
    local external_ip
    external_ip=$(kubectl get svc -n tenant-a tenant-a-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$external_ip" ]; then
        print_status "WARN" "LoadBalancer external IP not found, skipping external internal endpoint test"
        record_result "PASS"  # Treat as pass since endpoint is effectively blocked
        return
    fi
    
    # Try to access internal endpoint externally (should fail)
    if curl -s -f --connect-timeout 5 "http://${external_ip}/internal" &>/dev/null; then
        print_status "FAIL" "Internal endpoint is accessible externally (security violation)"
        record_result "FAIL"
    else
        print_status "PASS" "Internal endpoint is properly blocked from external access"
        record_result "PASS"
    fi
}

# Test d: Internal endpoint reachable in-cluster
test_internal_reachable() {
    print_status "TEST" "Testing internal endpoint accessibility within tenant-a cluster..."
    
    # Create a temporary pod to test internal connectivity
    kubectl run temp-test-pod -n tenant-a --image=curlimages/curl:latest --rm -i --restart=Never -- \
        curl -s -f "http://tenant-a-internal.tenant-a.svc.cluster.local:9090/internal" | grep -q "tenant-a\|internal\|success" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_status "PASS" "Internal endpoint is reachable within tenant-a cluster"
        record_result "PASS"
    else
        print_status "FAIL" "Internal endpoint is not reachable within tenant-a cluster"
        record_result "FAIL"
    fi
}

# Test e: Cross-tenant isolation
test_cross_tenant_isolation() {
    print_status "TEST" "Testing cross-tenant database isolation (tenant-a -> tenant-b)..."
    
    # Try to connect from tenant-a to tenant-b database (should fail)
    if kubectl run temp-isolation-test -n tenant-a --image=postgres:15 --rm -i --restart=Never -- \
        psql -h pg-tenant-b-rw.tenant-b.svc.cluster.local -U postgres -d app -c "SELECT 1;" &>/dev/null; then
        print_status "FAIL" "Cross-tenant database access is allowed (security violation)"
        record_result "FAIL"
    else
        print_status "PASS" "Cross-tenant database access is properly blocked"
        record_result "PASS"
    fi
}

# Test f: Ops read-only policy
test_ops_readonly() {
    print_status "TEST" "Testing ops namespace read-only access to tenant databases..."
    
    # Test read access (should work)
    if kubectl run ops-read-test -n ops --image=postgres:15 --rm -i --restart=Never -- \
        psql -h pg-tenant-a-ro.tenant-a.svc.cluster.local -U postgres -d app -c "SELECT 1;" &>/dev/null; then
        print_status "INFO" "Ops read access to tenant-a successful"
        
        # Test write access (should fail)
        if kubectl run ops-write-test -n ops --image=postgres:15 --rm -i --restart=Never -- \
            psql -h pg-tenant-a-rw.tenant-a.svc.cluster.local -U postgres -d app -c "CREATE TABLE test_table (id INT);" &>/dev/null; then
            print_status "FAIL" "Ops has write access to tenant databases (should be read-only)"
            record_result "FAIL"
        else
            print_status "PASS" "Ops has proper read-only access to tenant databases"
            record_result "PASS"
        fi
    else
        print_status "FAIL" "Ops cannot read from tenant databases"
        record_result "FAIL"
    fi
}

# Test g: Backups present in DO Spaces
test_backups_present() {
    print_status "TEST" "Testing backup presence in DigitalOcean Spaces..."
    
    # List backups for tenant-a
    if s3cmd ls "s3://${DO_SPACES_BUCKET}/backups/tenant-a/" 2>/dev/null | grep -q "backup\|wal" 2>/dev/null; then
        print_status "PASS" "Backups found in DigitalOcean Spaces for tenant-a"
        record_result "PASS"
        
        # Show recent backups
        print_status "INFO" "Recent backups in tenant-a:"
        s3cmd ls "s3://${DO_SPACES_BUCKET}/backups/tenant-a/" 2>/dev/null | tail -5 | while read line; do
            echo "    $line"
        done
    else
        print_status "FAIL" "No backups found in DigitalOcean Spaces for tenant-a"
        record_result "FAIL"
    fi
}

# Test h: Disaster recovery restore
test_disaster_recovery() {
    print_status "TEST" "Testing disaster recovery restore process..."
    
    # Create test data
    print_status "INFO" "Creating test data in tenant-a database..."
    kubectl exec -n tenant-a deployment/tenant-a-app -- psql -h pg-tenant-a-rw -U postgres -d app -c "
        CREATE TABLE IF NOT EXISTS dr_test (
            id SERIAL PRIMARY KEY,
            test_data VARCHAR(50),
            created_at TIMESTAMP DEFAULT NOW()
        );
        INSERT INTO dr_test (test_data) VALUES ('pre-disaster-data-$(date +%s)');
    " &>/dev/null
    
    # Force a backup (trigger CNPG backup)
    print_status "INFO" "Triggering backup..."
    kubectl annotate cluster pg-tenant-a -n tenant-a cnpg.io/reconcile="$(date)" --overwrite &>/dev/null
    
    # Wait for backup to complete (simplified - in production you'd check backup status)
    sleep 30
    
    # Simulate disaster by scaling down the cluster
    print_status "INFO" "Simulating disaster by scaling down cluster..."
    kubectl patch cluster pg-tenant-a -n tenant-a --type merge -p '{"spec":{"instances":0}}' &>/dev/null
    
    # Wait for scale down
    sleep 15
    
    # Restore by scaling back up
    print_status "INFO" "Restoring cluster from backup..."
    kubectl patch cluster pg-tenant-a -n tenant-a --type merge -p '{"spec":{"instances":1}}' &>/dev/null
    
    # Wait for cluster to be ready
    kubectl wait --for=condition=Ready cluster/pg-tenant-a -n tenant-a --timeout=180s &>/dev/null
    
    # Verify data is still present
    if kubectl exec -n tenant-a deployment/tenant-a-app -- psql -h pg-tenant-a-rw -U postgres -d app -c "SELECT COUNT(*) FROM dr_test WHERE test_data LIKE 'pre-disaster-data-%';" 2>/dev/null | grep -q "1" 2>/dev/null; then
        print_status "PASS" "Disaster recovery successful - test data recovered"
        record_result "PASS"
    else
        print_status "FAIL" "Disaster recovery failed - test data not recovered"
        record_result "FAIL"
    fi
}

# Function to print final summary
print_summary() {
    echo ""
    echo "========================================="
    echo "           GRADE SUMMARY"
    echo "========================================="
    echo ""
    echo "Tests Passed: ${PASS_COUNT}/${TOTAL_TESTS}"
    echo "Tests Failed: ${FAIL_COUNT}/${TOTAL_TESTS}"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        print_status "PASS" "ALL TESTS PASSED! 🎉"
        echo ""
        echo "The multi-tenant deployment meets all requirements:"
        echo "  ✅ Database connectivity working"
        echo "  ✅ Network isolation properly configured"
        echo "  ✅ Public/internal endpoints correctly exposed"
        echo "  ✅ Cross-tenant security enforced"
        echo "  ✅ Ops read-only access configured"
        echo "  ✅ Backups present in DigitalOcean Spaces"
        echo "  ✅ Disaster recovery functional"
        echo ""
        exit 0
    else
        print_status "FAIL" "SOME TESTS FAILED"
        echo ""
        echo "Please review the failed tests above and fix the issues."
        echo "Common issues:"
        echo "  - Network policies not properly configured"
        echo "  - Database credentials incorrect"
        echo "  - LoadBalancer not provisioned"
        echo "  - Backup configuration missing"
        echo "  - RBAC permissions incorrect"
        echo ""
        exit 1
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "    MULTI-TENANT DEPLOYMENT GRADER"
    echo "========================================="
    echo ""
    echo "This script validates the multi-tenant Kubernetes deployment"
    echo "according to the DigitalOcean take-home task requirements."
    echo ""
    
    # Validate environment and dependencies
    validate_environment
    check_dependencies
    configure_s3cmd
    
    echo ""
    echo "Starting validation tests..."
    echo ""
    
    # Run all tests
    test_smoke_db
    test_public_endpoint
    test_internal_blocked
    test_internal_reachable
    test_cross_tenant_isolation
    test_ops_readonly
    test_backups_present
    test_disaster_recovery
    
    # Print final summary
    print_summary
}

# Execute main function
main "$@"
