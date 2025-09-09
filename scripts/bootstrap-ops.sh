#!/bin/bash

set -e

echo "🚀 Bootstrapping ops namespace"

# Function to process template
process_template() {
    local template_name=$1
    local template_file="manifests/ops/${template_name}"
    
    # Apply the processed template
    kubectl apply -f "$template_file"
    
    echo "Applied: $template_name"
}

echo "📝 Processing ops templates..."

echo "🏠 Creating namespace..."
process_template "namespace.yaml"

echo "Creating RBAC roles and bindings..."
process_template "rbac.yaml"

echo "Creating psql-client..."
process_template "psql-client.yaml"

echo "✅ Ops namespace bootstrapped successfully!"
