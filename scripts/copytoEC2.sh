scp -i your-key.pem task-manager-app.tar.gz ec2-user@your-ec2-ip:~/
scp -i your-key.pem deploy.sh ec2-user@your-ec2-ip:~/


# Make the deploy script executable
chmod +x deploy.sh

# Run the deploy script with sudo
sudo ./deploy.sh