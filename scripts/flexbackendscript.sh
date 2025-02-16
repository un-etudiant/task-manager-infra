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
if ! command -v java &> /dev/null; then
    dnf install -y java-23-amazon-corretto-devel
fi

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /opt/task-manager-service/config
cd /opt/task-manager-service

# Extract application files
echo "📦 Extracting application files..."
tar -xzf ~/task-manager-service.tar.gz

# Create the environment file for production variables
cat > /opt/task-manager-service/config/application-prod.env << 'EOF'
# Database Configuration
DB_URL=jdbc:postgresql://your-rds-endpoint:5432/taskdb
DB_USERNAME=your_username
DB_PASSWORD=your_password

# AWS Configuration
AWS_REGION=us-east-1

# Application Configuration
SERVER_PORT=8080

# Add other environment variables as needed
EOF

# Create the run script with configurable options
cat > /opt/task-manager-service/run.sh << 'EOF'
#!/bin/bash

# Source the environment variables
set -a
source /opt/task-manager-service/config/application-prod.env
set +a

# Source the Java config file if it exists
if [ -f "/opt/task-manager-service/config/app.config" ]; then
    source /opt/task-manager-service/config/app.config
fi

# Default values if not set in app.config
JAVA_OPTS=${JAVA_OPTS:-""}
JAVA_AGENTS=${JAVA_AGENTS:-""}
JAVA_HEAP=${JAVA_HEAP:-"2g"}

# Build the complete Java command
CMD="java"
CMD="$CMD -Xmx$JAVA_HEAP"
CMD="$CMD $JAVA_OPTS"
CMD="$CMD -Dspring.profiles.active=prod"

# Add any Java agents
if [ ! -z "$JAVA_AGENTS" ]; then
    for agent in $JAVA_AGENTS; do
        CMD="$CMD -javaagent:$agent"
    done
fi

# Add the jar file
CMD="$CMD -jar task-manager-service.jar"

# Execute the command
exec $CMD
EOF

# Create Java config file
cat > /opt/task-manager-service/config/app.config << 'EOF'
# Java Options
JAVA_OPTS="-XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError"

# Java Agents (space-separated list of paths)
JAVA_AGENTS=""

# Heap size
JAVA_HEAP="2g"
EOF

# Set permissions
chmod +x /opt/task-manager-service/run.sh
chmod 600 /opt/task-manager-service/config/application-prod.env
chown -R ec2-user:ec2-user /opt/task-manager-service

# Create systemd service
echo "⚙️ Creating systemd service..."
cat > /etc/systemd/system/task-manager-service.service << 'EOF'
[Unit]
Description=Task Manager Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/task-manager-service
ExecStart=/opt/task-manager-service/run.sh
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

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
echo ""
echo "📝 Configuration files:"
echo "   1. Environment variables: /opt/task-manager-service/config/application-prod.env"
echo "   2. Java options: /opt/task-manager-service/config/app.config"
echo ""
echo "💡 To modify configuration:"
echo "   1. Edit the appropriate config file"
echo "   2. Restart with: sudo systemctl restart task-manager-service"
echo ""
echo "💡 To view logs:"
echo "   sudo journalctl -u task-manager-service -f"