#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting build process for task-manager-service..."

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo "❌ Error: pom.xml not found. Are you in the task-manager-service directory?"
    exit 1
fi

# Clean up previous build
echo "🧹 Cleaning up previous build..."
rm -rf target
rm -f task-manager-service.tar.gz

# Build the application
echo "🏗️ Building application with Maven..."
./mvnw clean package -DskipTests

# Create deployment package
echo "📦 Creating deployment package..."
mkdir -p deploy
cp target/*.jar deploy/task-manager-service.jar
cp src/main/resources/application.properties deploy/
cat > deploy/task-manager-service.service << 'EOF'
[Unit]
Description=Task Manager Service
After=network.target

[Service]
Type=simple
User=ec2-user
Environment="JAVA_HOME=/usr/lib/jvm/java-23-amazon-corretto"
Environment="SPRING_CONFIG_LOCATION=file:/opt/task-manager-service/application.properties"
WorkingDirectory=/opt/task-manager-service
ExecStart=/usr/lib/jvm/java-23-amazon-corretto/bin/java -jar task-manager-service.jar
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create the deployment tarball
tar -czf task-manager-service.tar.gz -C deploy .

echo "✅ Build complete! Created task-manager-service.tar.gz"
echo "📝 You can now copy task-manager-service.tar.gz to your EC2 instance"
echo "💡 Next step: Run deploy-java.sh on your EC2 instance"