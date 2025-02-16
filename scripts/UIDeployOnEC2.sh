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
if [ ! -f "task-manager-app.tar.gz" ]; then
    echo "❌ task-manager-app.tar.gz not found"
    exit 1
fi

# Install required packages if not present
echo "📦 Checking and installing required packages..."
if ! command -v nginx &> /dev/null; then
    amazon-linux-extras install nginx1 -y
fi

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /usr/share/nginx/html/task-manager-app
chown -R ec2-user:ec2-user /usr/share/nginx/html/task-manager-app

# Extract application files
echo "📦 Extracting application files..."
tar -xzf task-manager-app.tar.gz
cp -r dist/* /usr/share/nginx/html/task-manager-app/

# Configure Nginx
echo "⚙️ Configuring Nginx..."
cat > /etc/nginx/conf.d/task-manager-app.conf << 'EOF'
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html/task-manager-app;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Add security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Remove default nginx config if it exists
rm -f /etc/nginx/conf.d/default.conf

# Test Nginx configuration
echo "🔍 Testing Nginx configuration..."
nginx -t

# Start and enable Nginx
echo "🔄 Starting and enabling Nginx..."
systemctl start nginx
systemctl enable nginx

echo "✅ Deployment complete!"
echo "💡 Your application should now be running on port 80"
echo "📝 Check nginx logs with: tail -f /var/log/nginx/error.log"