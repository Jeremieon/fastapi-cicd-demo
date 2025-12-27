#!/bin/bash
set -e

DOCKER_IMAGE=$1
CONTAINER_NAME=$2
PORT=$3
ENVIRONMENT=$4
VERSION=$5

echo "🚀 Starting deployment..."
echo "   Image: $DOCKER_IMAGE"
echo "   Container: $CONTAINER_NAME"
echo "   Port: $PORT"
echo "   Environment: $ENVIRONMENT"

# Pull the new image
echo "📦 Pulling Docker image..."
docker pull $DOCKER_IMAGE

# Check if old container exists and backup its ID
OLD_CONTAINER_ID=""
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    OLD_CONTAINER_ID=$(docker ps -aq -f name=$CONTAINER_NAME)
    echo "📸 Backing up old container: $OLD_CONTAINER_ID"
    
    # Tag the old image for potential rollback
    OLD_IMAGE=$(docker inspect --format='{{.Image}}' $CONTAINER_NAME 2>/dev/null || echo "")
    if [ ! -z "$OLD_IMAGE" ]; then
        docker tag $OLD_IMAGE ${DOCKER_IMAGE}-rollback || true
        echo "✅ Old image tagged for rollback"
    fi
fi

# Stop old container (but don't remove yet - for rollback)
if [ ! -z "$OLD_CONTAINER_ID" ]; then
    echo "⏸️  Stopping old container..."
    docker stop $CONTAINER_NAME || true
fi

# Run new container
echo "🏃 Starting new container..."
docker run -d \
    --name ${CONTAINER_NAME}-new \
    --restart unless-stopped \
    -p $PORT:8000 \
    -e ENVIRONMENT=$ENVIRONMENT \
    -e APP_VERSION=$VERSION \
    $DOCKER_IMAGE

# Wait for container to start
echo "⏳ Waiting for container to be ready..."
sleep 5

# Health check
echo "🏥 Running health check..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:$PORT/health > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        
        # Remove old container
        if [ ! -z "$OLD_CONTAINER_ID" ]; then
            echo "🗑️  Removing old container..."
            docker rm $CONTAINER_NAME || true
        fi
        
        # Rename new container
        docker rename ${CONTAINER_NAME}-new $CONTAINER_NAME
        
        echo "🎉 Deployment successful!"
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⏳ Health check failed, retry $RETRY_COUNT/$MAX_RETRIES..."
    sleep 3
done

# Health check failed - rollback!
echo "❌ Health check failed after $MAX_RETRIES attempts"
echo "🔄 Rolling back to previous version..."

# Stop and remove failed container
docker stop ${CONTAINER_NAME}-new || true
docker rm ${CONTAINER_NAME}-new || true

# Restart old container
if [ ! -z "$OLD_CONTAINER_ID" ]; then
    docker start $CONTAINER_NAME || true
    echo "✅ Rolled back to previous version"
else
    echo "⚠️  No previous version to rollback to"
fi

echo "❌ Deployment failed!"
exit 1