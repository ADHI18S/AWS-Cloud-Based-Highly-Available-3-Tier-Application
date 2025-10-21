text
# 🎓 College Exam Result Website – AWS 3-Tier Architecture

![AWS](https://img.shields.io/badge/AWS-3--Tier-orange?logo=amazon-aws)
![Region](https://img.shields.io/badge/Region-us--east--2-blue)
![Python](https://img.shields.io/badge/Python-3.10-blue?logo=python)
![Flask](https://img.shields.io/badge/Flask-2.3.3-green)
![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)
![NGINX](https://img.shields.io/badge/NGINX-latest-green?logo=nginx)
![Status](https://img.shields.io/badge/Status-Production-brightgreen)

A modern, scalable, and secure web application that allows students to securely check their exam results, implemented as a **3-tier architecture on AWS** with full auto scaling, load balancing, and Multi-AZ best practices.


![3-tier architecture on AWS](<3 trier  (1).png>)

![preview](<Screenshot 2025-10-21 183713.png>)


## 🏗️ Project Architecture

- **Web Tier:** NGINX EC2 ASG in public subnets, external ALB
- **App Tier:** Flask API EC2 ASG in private subnets, internal ALB
- **Database Tier:** RDS MySQL Multi-AZ in private subnets

See [docs/architecture.md](docs/architecture.md) for detailed explanation.

---

## ✨ Features

- Multi-AZ high availability (us-east-2)
- Auto Scaling for web and app tiers (1–3 instances each)
- Application Load Balancers (external + internal)
- RDS MySQL Multi-AZ with automatic failover
- End-to-end HTTPS with AWS ACM SSL certificate
- Route 53 DNS integration (custom domains supported)
- Complete CI/CD, security, and backup best practices

---

## 📁 Repository Structure

3-TIER-EXAM-RESULT-WEBSITE/
│
├── app-server/
│ ├── app.py # Flask application
│ ├── admin_utils.py # CLI tools
│ ├── config.example.py # Template config
│ ├── database_schema.sql # DB schema
│ ├── gunicorn.conf.py # Gunicorn config
│ └── requirements.txt
│
├── web-server/
│ ├── index.html
│ ├── nginx.conf
│ ├── script.js
│ └── styles.css
│
├── infrastructure/
│ ├── vpc-setup.md
│ ├── rds-config.json
│ └── security-groups.json
│
├── docs/
│ ├── api-documentation.md
│ ├── architecture.md
│ ├── AWS-ACM.md
│ ├── deployment-guide.md
│ ├── installation.md
│ ├── Route53.md
│ ├── SECURITY.md
│
├── .gitignore
└── README.md

text

---

## 🚀 Quick Start

### **Local Development**

git clone https://github.com/vsanthoshraj/3-tier-exam-result-website.git
cd 3-tier-exam-result-website/app-server

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

mysql -u root -p # create DB/user/tables using schema.sql

cp config.example.py config.py # edit with your credentials

python3 app.py # access via http://localhost:5000

text

See [docs/installation.md](docs/installation.md) for full details.

---

## 🌍 Production Deployment

- See [docs/deployment-guide.md](docs/deployment-guide.md) for AWS setup, including VPC, networking, security, EC2 launch, load balancers, auto scaling, and SSL.
- Attach custom domain with [docs/Route53.md](docs/Route53.md) and SSL with [docs/AWS-ACM.md](docs/AWS-ACM.md).

---

## 🔒 Security

- HTTPS with AWS ACM
- SQL Injection prevention (parameterized queries)
- Security groups: principle of least privilege
- EC2 and DB in private subnets
- No secrets in repo ([see SECURITY.md](docs/SECURITY.md))

---

## 📖 Documentation

- [Architecture](docs/architecture.md)
- [Deployment guide](docs/deployment-guide.md)
- [API reference](docs/api-documentation.md)
- [Security](docs/SECURITY.md)
- [Installation](docs/installation.md)
- [Route53 DNS](docs/Route53.md)
- [AWS ACM SSL](docs/AWS-ACM.md)

---

## 👨‍💻 Author

Santhosh Raj V  
GitHub: [@vsanthoshraj](https://github.com/vsanthoshraj)  
Email: santhoshrajv10@gmail.com

---


