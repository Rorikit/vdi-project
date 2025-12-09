#!/bin/bash

set -e

echo "=== VDI Deployment Script ==="
echo "Started at: $(date)"

# 1. Build Docker image
echo "Building Docker image..."
cd ~/vdi-project
docker build -t vdi-desktop:latest -f dockerfiles/Dockerfile.xfce-desktop dockerfiles/

# 2. Stop old containers
echo "Stopping old containers..."
docker-compose down || true

# 3. Start new containers
echo "Starting new containers..."
docker-compose up -d

# 4. Wait for containers to start
echo "Waiting for containers to start..."
sleep 10

# 5. Check status
echo "Container status:"
docker-compose ps

# 6. Show connection info
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=== VDI Infrastructure Ready ==="
echo "Server IP: ${SERVER_IP}"
echo ""
echo "Access Methods:"
echo "1. Direct RDP (from Windows):"
echo "   - Desktop 1: ${SERVER_IP}:3391"
echo "   - Desktop 2: ${SERVER_IP}:3392"
echo "   Username: student"
echo "   Password: student123"
echo ""
echo "2. Web Gateway (Guacamole):"
echo "   - URL: http://${SERVER_IP}:8080/guacamole"
echo "   Default login: guacadmin / guacadmin"
echo ""
echo "3. From Host machine (Windows 11):"
echo "   - SSH: ssh user@${SERVER_IP}"
echo ""
echo "Deployment completed at: $(date)"
