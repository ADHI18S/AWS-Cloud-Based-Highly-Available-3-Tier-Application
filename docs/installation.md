# 📦 Installation Guide

This guide provides step-by-step instructions to install the College Exam Result Website locally, on Ubuntu servers, and for AWS production deployments.

---

## Table of Contents

1. Local Development Setup
2. Ubuntu Server Manual Setup
3. AWS Production Deployment
4. Troubleshooting

---

## 1. Local Development Setup

### Prerequisites
- Python 3.8+
- MySQL 8.0+
- Git

### Steps

git clone https://github.com/vsanthoshraj/university-exam-result-website.git
cd university-exam-result-website

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

mysql -u root -p


In MySQL shell:

CREATE DATABASE college_results CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'collegeuser'@'localhost' IDENTIFIED BY 'YourPassword123!';
GRANT ALL PRIVILEGES ON college_results.* TO 'collegeuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;


Import schema:

mysql -u collegeuser -p college_results < database_schema.sql

text

Configure app:

cp config.example.py config.py
nano config.py # update credentials

text

Run app:

python3 app.py

text

Access at `http://localhost:5000`

---

## 2. Ubuntu Server Manual Setup

*Similar to local dev plus:*

sudo apt update && sudo apt upgrade -y
sudo apt install apache2 libapache2-mod-wsgi-py3 python3-pip python3-venv mysql-server libmysqlclient-dev git

cd /var/www
sudo git clone https://github.com/vsanthoshraj/university-exam-result-website.git collegeresults-app
cd collegeresults-app

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

sudo mysql_secure_installation

sudo mysql <<EOF
CREATE DATABASE college_results CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'collegeuser'@'localhost' IDENTIFIED BY 'SecurePassword123!';
GRANT ALL PRIVILEGES ON college_results.* TO 'collegeuser'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql -u collegeuser -pcollege_results < database_schema.sql

cp config.example.py config.py
nano config.py

sudo nano /etc/apache2/sites-available/collegeresults.conf


Add Apache WSGI config in the file, then:

sudo systemctl restart apache2


---

## 3. AWS Production Deployment

*Refer to DEPLOYMENT.md for detailed instructions.*

---

## 4. Troubleshooting

### Common Problems and Fixes

- MySQL connection issues
- Missing Python modules
- Apache permission errors
- Ports busy conflicts

---

_Last updated: October 2025_
