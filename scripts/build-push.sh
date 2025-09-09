#!/bin/bash

set -e

TENANT_NAME=$1
REGISTRY_ENDPOINT="registry.digitalocean.com"
REGISTRY_NAME="alaris-takehome-task-registry"

if [ -z "$TENANT_NAME" ]; then
    echo "Usage: $0 <tenant-name>"
    echo "Example: $0 tenant-a"
    exit 1
fi

IMAGE_NAME="${REGISTRY_ENDPOINT}/${REGISTRY_NAME}/${TENANT_NAME}/tenant-app"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building image: $FULL_IMAGE"

echo "Logging into DigitalOcean Container Registry..."
doctl registry login

TIMESTAMP=$(date +%s)
echo "Building Docker image (forced rebuild)..."
docker build --no-cache -t "$FULL_IMAGE" \
    --build-arg TENANT_NAME="$TENANT_NAME" \
    --build-arg BUILD_TIMESTAMP="$TIMESTAMP" \
    ./app

echo "Pushing image to registry..."
docker push "$FULL_IMAGE"

# tag and push with timestamp for versioning
TIMESTAMPED_IMAGE="${IMAGE_NAME}:${TIMESTAMP}"
docker tag "$FULL_IMAGE" "$TIMESTAMPED_IMAGE"
docker push "$TIMESTAMPED_IMAGE"

echo "Successfully built and pushed:"
echo "Latest: $FULL_IMAGE"
echo "Versioned: $TIMESTAMPED_IMAGE"
