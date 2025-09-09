#!/bin/bash

set -e

TENANT_NAME=$1

if [ -z "$TENANT_NAME" ]; then
    echo "Usage: $0 <tenant-name>"
    echo "Example: $0 tenant-a"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is not set."
    exit 1
fi

echo "🚀 Bootstrapping tenant: $TENANT_NAME"

export TENANT_NAME="$TENANT_NAME"
export DB_PASSWORD="$DB_PASSWORD"
export DO_SPACES_ACCESS_KEY="$DO_SPACES_ACCESS_KEY"
export DO_SPACES_SECRET_KEY="$DO_SPACES_SECRET_KEY"

# Function to process template
process_template() {
    local template_name=$1
    local template_file="manifests/${template_name}"
    local temp_file="/tmp/${TENANT_NAME}-${template_name}"
    
    if [ ! -f "$template_file" ]; then
        echo "Error: Template file not found: $template_file"
        exit 1
    fi
    
    echo "Processing template: $template_name"
    
    # Copy template and replace all variables
    cp "$template_file" "$temp_file"
    
    # Replace all template variables using environment variables
    # Find all {{VARIABLE}} patterns and replace them
    for var_name in $(grep -o '{{[^}]*}}' "$temp_file" | sort -u | sed 's/[{}]//g'); do
        if [ -n "${!var_name}" ]; then
            sed -i "s|{{$var_name}}|${!var_name}|g" "$temp_file"
        else
            echo "⚠️ Warning: Template variable $var_name not set"
        fi
    done
    
    # Apply the processed template
    kubectl apply -f "$temp_file"
    rm -f "$temp_file"
    
    echo "Applied: $template_name"
}

# Process and apply templates in order
echo "📝 Processing templates..."

echo "🏠 Creating namespace..."
process_template "manifests/namespace.yaml"

echo "🔐 Creating secrets..."
process_template "manifests/secrets.yaml"

# echo "🗄️ Creating PostgreSQL cluster..."
# process_template "manifests/database.yaml"

# echo "🚀 Deploying application..."
# process_template "manifests/application.yaml"

# echo "🌐 Creating services..."
# process_template "manifests/services.yaml"

# echo "🔒 Applying network policies..."
# process_template "manifests/network-policies.yaml"

# Wait for resources
# echo "⏳ Waiting for resources to be ready..."
# kubectl wait --for=condition=Ready cluster/pg-$TENANT_NAME -n $TENANT_NAME --timeout=300s
# kubectl wait --for=condition=Available deployment/${TENANT_NAME}-app -n $TENANT_NAME --timeout=300s

# # Initialize database
# echo "📊 Initializing database..."
# sleep 30  # Wait for app to be fully ready
# kubectl exec -n $TENANT_NAME deployment/${TENANT_NAME}-app -- psql -h pg-${TENANT_NAME}-rw -U postgres -d app -c "
# CREATE TABLE IF NOT EXISTS tenant_info (
#   id SERIAL PRIMARY KEY,
#   tenant_name VARCHAR(50) NOT NULL,
#   created_at TIMESTAMP DEFAULT NOW()
# );
# INSERT INTO tenant_info (tenant_name) VALUES ('$TENANT_NAME') ON CONFLICT DO NOTHING;
# "

# # Get external IP and show results
# EXTERNAL_IP=$(kubectl get svc -n $TENANT_NAME ${TENANT_NAME}-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

echo ""
echo "✅ Tenant $TENANT_NAME bootstrapped successfully!"
# echo ""
# echo "📋 Connection Information:"
# echo "  External IP: $EXTERNAL_IP"
# echo "  Public endpoint: http://$EXTERNAL_IP/public"
# echo ""
# echo "🧪 Test commands:"
# echo "  curl http://$EXTERNAL_IP/public"
# echo "  kubectl logs -n $TENANT_NAME deployment/${TENANT_NAME}-app"allow-spaces
#   namespace: $TENANT_NAME
# spec:
#   podSelector:
#     matchLabels:
#       cnpg.io/cluster: pg-$TENANT_NAME
#   policyTypes:
#   - Egress
#   egress:
#   - to: []
#     ports:
#     - protocol: TCP
#       port: 443
# EOF

# # 7. Wait for resources
# echo "⏳ Waiting for resources to be ready..."
# kubectl wait --for=condition=Ready cluster/pg-$TENANT_NAME -n $TENANT_NAME --timeout=300s
# kubectl wait --for=condition=Available deployment/${TENANT_NAME}-app -n $TENANT_NAME --timeout=300s

# # 8. Initialize database
# echo "📊 Initializing database..."
# sleep 30  # Wait for app to be fully ready
# kubectl exec -n $TENANT_NAME deployment/${TENANT_NAME}-app -- psql -h pg-${TENANT_NAME}-rw -U postgres -d app -c "
# CREATE TABLE IF NOT EXISTS tenant_info (
#   id SERIAL PRIMARY KEY,
#   tenant_name VARCHAR(50) NOT NULL,
#   created_at TIMESTAMP DEFAULT NOW()
# );
# INSERT INTO tenant_info (tenant_name) VALUES ('$TENANT_NAME') ON CONFLICT DO NOTHING;
# "

# # 9. Get external IP and show results
# EXTERNAL_IP=$(kubectl get svc -n $TENANT_NAME ${TENANT_NAME}-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

# echo ""
# echo "✅ Tenant $TENANT_NAME bootstrapped successfully!"
# echo ""
# echo "📋 Connection Information:"
# echo "  External IP: $EXTERNAL_IP"
# echo "  Public endpoint: http://$EXTERNAL_IP/public"
# echo "  Image: ${REGISTRY_ENDPOINT}/${REGISTRY_NAME}/${TENANT_NAME}/tenant-app:latest"
# echo ""
# echo "🧪 Test commands:"
# echo "  curl http://$EXTERNAL_IP/public"
# echo "  kubectl logs -n $TENANT_NAME deployment/${TENANT_NAME}-app"
