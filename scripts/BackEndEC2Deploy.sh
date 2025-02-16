#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting deployment process..."

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Check for deployment package
if [ ! -f "task-manager-service.tar.gz" ]; then
    echo "❌ task-manager-service.tar.gz not found"
    exit 1
fi

# Install Java if not present
echo "📦 Checking and installing Java..."
if ! command -v java &> /dev/null; then
    # Install Java 23 Corretto
    dnf install -y java-23-amazon-corretto-devel
fi

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /opt/task-manager-service
chown -R ec2-user:ec2-user /opt/task-manager-service

# Extract application files
echo "📦 Extracting application files..."
tar -xzf task-manager-service.tar.gz -C /opt/task-manager-service/

# Set permissions
chown -R ec2-user:ec2-user /opt/task-manager-service
chmod +x /opt/task-manager-service/task-manager-service.jar

# Install systemd service
echo "⚙️ Installing systemd service..."
cp /opt/task-manager-service/task-manager-service.service /etc/systemd/system/

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Start and enable service
echo "▶️ Starting service..."
systemctl start task-manager-service
systemctl enable task-manager-service

echo "✅ Deployment complete!"
echo "💡 Service status:"
systemctl status task-manager-service
echo "📝 Check logs with: journalctl -u task-manager-service -f"