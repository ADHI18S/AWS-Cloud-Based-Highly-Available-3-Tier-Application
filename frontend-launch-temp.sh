#!/bin/bash

set -e

LOG=/var/log/college-results-web-startup.log
exec > >(tee -a "$LOG") 2>&1

echo "===== College Results Web startup started ====="

echo "===== Installing packages ====="

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx git

echo "===== Cloning repository ====="

rm -rf /tmp/college-results-repo

git clone https://github.com/ADHI18S/temp.git \
    /tmp/college-results-repo

echo "===== Repository contents ====="

find /tmp/college-results-repo -maxdepth 3 -type f -print

echo "===== Searching for frontend ====="

INDEX_FILE=$(find /tmp/college-results-repo \
    -type f \
    -name "index.html" \
    -not -path "*/.git/*" \
    | head -1)

if [ -z "$INDEX_FILE" ]; then
    echo "ERROR: index.html was not found"
    exit 1
fi

FRONTEND_DIR=$(dirname "$INDEX_FILE")

echo "Frontend directory:"
echo "$FRONTEND_DIR"

echo "===== Installing frontend ====="

rm -rf /var/www/html
mkdir -p /var/www/html

cp -r "$FRONTEND_DIR"/* /var/www/html/

echo "===== Frontend installed ====="

ls -lah /var/www/html/

echo "===== Creating NGINX configuration ====="

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/college-results

cat > /etc/nginx/sites-available/college-results <<'NGINX'

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.html;

    location = /health {
        access_log off;
        default_type text/plain;
        return 200 "healthy\n";
    }

    location /api/ {
        proxy_pass http://internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com;   #change your alb dns value

        proxy_http_version 1.1;

        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;

    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root /usr/share/nginx/html;
    }
}

NGINX

echo "===== Enabling NGINX site ====="

ln -sf \
    /etc/nginx/sites-available/college-results \
    /etc/nginx/sites-enabled/college-results

echo "===== Testing NGINX ====="

nginx -t

echo "===== Starting NGINX ====="

systemctl enable nginx
systemctl restart nginx

echo "===== Testing /health ====="

curl -f http://127.0.0.1/health

echo "===== Testing frontend ====="

curl -f http://127.0.0.1/

echo "===== College Results Web startup completed successfully ====="