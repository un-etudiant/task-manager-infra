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
cp src/main/resources/application.yaml deploy/
cp src/main/resources/application-prod.yaml deploy/

# Create deployment tarball
tar -czf task-manager-service.tar.gz -C deploy .

echo "✅ Build complete! Created task-manager-service.tar.gz"
echo "📝 You can now copy task-manager-service.tar.gz to your EC2 instance"
echo "💡 Next step: Run deploy-java.sh on your EC2 instance"