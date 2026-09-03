#!/bin/bash

set -e

LOG=/var/log/college-results-startup.log
exec > >(tee -a $LOG) 2>&1

echo "===== College Results App startup started ====="

# Update packages
apt-get update -y

# Install required packages
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    pkg-config \
    default-libmysqlclient-dev \
    git

# Application directory
mkdir -p /opt/college-results/app-server

# Clone application
rm -rf /opt/college-results/app-server/temp

git clone https://github.com/ADHI18S/temp.git \
    /opt/college-results/app-server/temp

cd /opt/college-results/app-server/temp

echo "Application cloned successfully"

# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install application dependencies
pip install -r requirements.txt

echo "Python dependencies installed"

# Create environment file
cat > /opt/college-results/app-server/temp/.env <<'EOF'
MYSQL_HOST=college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com
MYSQL_PORT=3306
MYSQL_USER=collegeuser
MYSQL_PASSWORD= xxxxxxx  #change your passwd  its for only testing for productio use external tools such as secret manager
MYSQL_DB=college_results
APP_PORT=8000
DEBUG=False
EOF

chmod 600 /opt/college-results/app-server/temp/.env

echo ".env created"

# Create Gunicorn systemd service
cat > /etc/systemd/system/college-results.service <<'EOF'
[Unit]
Description=College Results Flask Application
After=network.target

[Service]
User=ssm-user
Group=ssm-user
WorkingDirectory=/opt/college-results/app-server/temp
Environment="PATH=/opt/college-results/app-server/temp/venv/bin"
ExecStart=/opt/college-results/app-server/temp/venv/bin/gunicorn -c gunicorn.conf.py app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service created"

# Make sure application files belong to ssm-user
chown -R ssm-user:ssm-user /opt/college-results

# Reload systemd
systemctl daemon-reload

# Enable service at boot
systemctl enable college-results.service

# Start application
systemctl start college-results.service

echo "===== College Results App startup completed ====="

# Show status
systemctl status college-results.service --no-pager