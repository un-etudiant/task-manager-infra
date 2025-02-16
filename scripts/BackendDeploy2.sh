#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting deployment process..."

# Check for deployment package
if [ ! -f "task-manager-service.tar.gz" ]; then
    echo "❌ task-manager-service.tar.gz not found"
    exit 1
fi

# Install Java if not present
if ! command -v java &> /dev/null; then
    sudo dnf install -y java-23-amazon-corretto-devel
fi

# Create application directory
echo "📁 Creating application directory..."
mkdir -p ~/task-manager-service
cd ~/task-manager-service

# Extract application files
echo "📦 Extracting application files..."
tar -xzf ../task-manager-service.tar.gz

# Create a run script that can be easily modified
cat > run.sh << 'EOF'
#!/bin/bash

# Add any Java agents or JVM options here
JAVA_OPTS=""
# JAVA_OPTS="$JAVA_OPTS -javaagent:/path/to/agent.jar"
# JAVA_OPTS="$JAVA_OPTS -Xmx2g"
# JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"

# Run the application
java $JAVA_OPTS -jar task-manager-service.jar
EOF

chmod +x run.sh

echo "✅ Deployment complete!"
echo "💡 To run the service:"
echo "   cd ~/task-manager-service"
echo "   ./run.sh"
echo ""
echo "💡 To run with a Java agent:"
echo "   1. Edit run.sh"
echo "   2. Uncomment and modify the JAVA_OPTS line"
echo "   3. Run ./run.sh"
echo ""
echo "💡 To run in background:"
echo "   nohup ./run.sh > app.log 2>&1 &"
echo "   tail -f app.log"