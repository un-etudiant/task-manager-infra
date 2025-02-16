#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting build process for task-manager-app..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Are you in the task-manager-app directory?"
    exit 1
fi

# Clean up previous build
echo "🧹 Cleaning up previous build..."
rm -rf dist
rm -f task-manager-app.tar.gz

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Run build
echo "🏗️ Building application..."
npm run build

# Create deployment package
echo "📦 Creating deployment package..."
tar -czf task-manager-app.tar.gz dist/

echo "✅ Build complete! Created task-manager-app.tar.gz"
echo "📝 You can now copy task-manager-app.tar.gz to your EC2 instance"
echo "💡 Next step: Run deploy.sh on your EC2 instance"