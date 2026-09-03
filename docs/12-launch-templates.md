# EC2 Launch Templates & User Data

## 1. What is it?
An EC2 Launch Template is an immutable configuration specification that defines instance parameters (AMI, instance type, key pair, security groups, IAM role, block storage, and User Data bootstrap scripts) used by Auto Scaling Groups to launch identical EC2 instances.

## 2. Why are we using it?
To automate instance provisioning, eliminate manual server configuration, enforce version control, and support self-healing Auto Scaling deployments.

## 3. Where does it fit in our architecture?
Drives automated instance creation for both Web and App Auto Scaling Groups.

## 4. Architecture
```
Launch Template (Version 1/2) ---> Auto Scaling Group ---> Automated EC2 Instance Provisioning
```

## 5. Configuration used in this project
- `college-results-web-lt`: Ubuntu 22.04 LTS, `t3.micro`, `Web-SG`, `frontend-launch-temp.sh` User Data script.
- `college-results-app-lt`: Ubuntu 22.04 LTS, `t3.micro`, `App-SG`, IAM Profile `college-results-app-ssm-role`, `backend-launch-temp.sh` User Data script.

> 📸 Screenshot: EC2 Launch Templates Console
> ![Launch Templates](images/launch-templates.png)

## 6. Step-by-step User Data Analysis
### Web User Data (`frontend-launch-temp.sh`)
```bash
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y nginx git
rm -rf /tmp/college-results-repo
git clone https://github.com/ADHI18S/temp.git /tmp/college-results-repo
rm -rf /var/www/html/*
cp -r /tmp/college-results-repo/* /var/www/html/
cat > /etc/nginx/sites-available/college-results <<'NGINX'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    location = /health { return 200 "healthy\n"; }
    location /api/ {
        proxy_pass http://internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/college-results /etc/nginx/sites-enabled/college-results
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
```

### App User Data (`backend-launch-temp.sh`)
```bash
#!/bin/bash
set -e
apt-get update -y && apt-get install -y python3-pip python3-venv git
mkdir -p /opt/college-results/app-server
git clone https://github.com/ADHI18S/temp.git /opt/college-results/app-server/temp
cd /opt/college-results/app-server/temp
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cat > .env <<'EOF'
MYSQL_HOST=college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com
MYSQL_USER=collegeuser
MYSQL_PASSWORD=YourSecurePassword123!
MYSQL_DB=college_results
APP_PORT=8000
EOF
systemctl enable college-results.service && systemctl start college-results.service
```

## 7. How it communicates with other components
Executed by `cloud-init` at initial boot as the `root` user to install packages and join target groups.

## 8. Security configuration
- User Data scripts should draw sensitive passwords from AWS Systems Manager Parameter Store rather than hardcoded script text.

## 9. Validation
Inspect User Data execution logs on an instance:
```bash
sudo tail -n 100 /var/log/cloud-init-output.log
sudo sed -n '1,100p' /var/lib/cloud/instance/user-data.txt
```

## 10. Troubleshooting
- **Issue**: ASG launches instances but application service does not start.
- **Cause**: User Data script syntax error or broken repository URL causing `cloud-init` failure.
- **Fix**: Inspect `/var/log/cloud-init-output.log` for script execution failure details.

## 11. Common mistakes
- Updating a Launch Template to Version 2 without updating the Auto Scaling Group to point to Version 2 or `$Latest`.

## 12. Production recommendations
- Bake pre-configured Golden AMIs using AWS Packer to accelerate instance startup time.

## 13. Related components
- Auto Scaling Groups
- EC2 User Data
- IAM Instance Profiles

## 14. What we learned
Launch Template version management is critical; ASGs do not automatically deploy new template versions unless explicitly updated.
