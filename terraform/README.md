# 🏗️ AWS 3-Tier Infrastructure with Terraform

This project automates the creation of a production-ready, modular, and cost-optimized **3-Tier Infrastructure on AWS** for the **College Exam Result Website** using Terraform.

---

## 📐 Architecture Overview

```text
                    INTERNET
                        │
                       IGW
                        │
       ┌────────────────┴────────────────┐
       ▼                                 ▼
 Public-Web-2a                     Public-Web-2b
 (10.0.1.0/24)                     (10.0.2.0/24)
 [NAT Gateway + EIP]
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
 Private-App-2a                   Private-App-2b
 (10.0.3.0/24)                     (10.0.4.0/24)
 ┌───────────────┐                 ┌───────────────┐
 │ App Server 2a │                 │ App Server 2b │
 └───────┬───────┘                 └───────┬───────┘
         │ (Port 3306)                     │ (Port 3306)
         └────────────────┬────────────────┘
                          ▼
             Private-DB-2a / Private-DB-2b
             (10.0.5.0/24) / (10.0.6.0/24)
             ┌──────────────────────────┐
             │     RDS MySQL Instance   │
             │   (college-results-db)   │
             └──────────────────────────┘
```

> [!NOTE]
> **Cost Optimization Design**: This infrastructure deploys a **single NAT Gateway in `Public-Web-2a`** to optimize AWS runtime costs (~$32/month savings), with both private application subnets routing outbound Internet traffic through `Public-Web-2a`.

---

## 📌 Subnet & Availability Zone Matrix

Subnets are deterministically mapped to Availability Zones (`count.index % length(var.availability_zones)`):

| Subnet Name | Type | CIDR Block | Availability Zone | Outbound Target |
| :--- | :--- | :---: | :---: | :--- |
| **Public-Web-2a** | Public | `10.0.1.0/24` | `us-east-2a` | `0.0.0.0/0` ➔ Internet Gateway |
| **Public-Web-2b** | Public | `10.0.2.0/24` | `us-east-2b` | `0.0.0.0/0` ➔ Internet Gateway |
| **Private-App-2a** | Private | `10.0.3.0/24` | `us-east-2a` | `0.0.0.0/0` ➔ NAT Gateway (`Public-Web-2a`) |
| **Private-App-2b** | Private | `10.0.4.0/24` | `us-east-2b` | `0.0.0.0/0` ➔ NAT Gateway (`Public-Web-2a`) |
| **Private-DB-2a** | Private | `10.0.5.0/24` | `us-east-2a` | Isolated (`10.0.0.0/16` Local Only) |
| **Private-DB-2b** | Private | `10.0.6.0/24` | `us-east-2b` | Isolated (`10.0.0.0/16` Local Only) |

---

## 🛡️ Security Group Chaining Architecture

Security groups strictly enforce the principle of least privilege through chained security group references:

```text
Internet ──(80/443)──► external_alb_sg ──(80)──► web_sg ──(8000)──► internal_alb_sg ──(8000)──► app_sg ──(3306)──► db_sg
```

### Security Group Inbound Specifications:
1. **`external_alb_sg`**: Accepts HTTP (80) and HTTPS (443) from `0.0.0.0/0`.
2. **`web_sg`**: Accepts HTTP (80) **only from `external_alb_sg`**, SSH (22) from `admin_ip_cidr`.
3. **`internal_alb_sg`**: Accepts Port 8000 **only from `web_sg`**.
4. **`app_sg`**: Accepts Port 8000 **only from `internal_alb_sg`**, SSH (22) from `admin_ip_cidr`.
5. **`db_sg`**: Accepts MySQL (3306) **only from `app_sg`**. Public database access is completely blocked.

---

## 📂 Project Structure

```text
terraform/
├── user_data/
│   └── app_server.sh            # Bootstrap script for App EC2 instances
├── modules/
│   ├── network/                 # VPC, Subnets, IGW, NAT GW, Route Tables
│   └── security-groups/         # 5 Chained Security Groups
├── ec2_app.tf                   # Private App EC2 Instances (App-2a & App-2b)
├── rds.tf                       # RDS MySQL Database Instance
├── main.tf                      # Root module declarations
├── variables.tf                 # Variable declarations & defaults
├── locals.tf                    # Common tags & naming conventions
├── outputs.tf                   # Root module outputs
├── providers.tf                 # AWS provider setup
├── versions.tf                  # Required Terraform version requirements
└── terraform.tfvars             # Environment variable configuration values
```

---

## 🚀 Step-by-Step Deployment Guide

Follow these steps to deploy or manage the Terraform infrastructure:

### Step 1: Navigate to the Terraform Directory
```bash
cd /home/adhithyan/AWS_3tier_project/terraform
```

### Step 2: Initialize Terraform Workspace
Initialize provider plugins and modules:
```bash
terraform init
```

### Step 3: Configure Variables (`terraform.tfvars`)
Ensure your `terraform.tfvars` file contains the desired parameters:
```hcl
aws_region          = "us-east-2"
project_name        = "college-results"
environment         = "prod"
single_nat_gateway  = true

# Database Credentials
db_username         = "collegeuser"
db_password         = "YourSecurePassword123!"
db_instance_class   = "db.t3.micro"
db_multi_az         = false

# EC2 Instance Settings
instance_type       = "t3.micro"
application_repo    = ""
```

### Step 4: Validate Formatting & Syntax
Format and validate the Terraform code:
```bash
terraform fmt -recursive
terraform validate
```

### Step 5: Generate & Review Execution Plan
Review the infrastructure changes before applying:
```bash
terraform plan
```

### Step 6: Deploy Infrastructure
Apply the configuration to create all AWS resources:
```bash
terraform apply
```

---

## 🔍 Exported Outputs

Upon successful completion, Terraform exposes the following outputs:

```hcl
# VPC & Subnet Outputs
vpc_id                   # ID of the VPC
public_subnet_ids        # IDs of Public Web Subnets (2a, 2b)
private_app_subnet_ids   # IDs of Private App Subnets (2a, 2b)
private_db_subnet_ids    # IDs of Private DB Subnets (2a, 2b)
nat_gateway_id           # ID of Single NAT Gateway

# Security Group Outputs
external_alb_sg_id       # ID of External ALB Security Group
web_sg_id                # ID of Web Tier Security Group
internal_alb_sg_id       # ID of Internal ALB Security Group
app_sg_id                # ID of App Tier Security Group
db_sg_id                 # ID of DB Tier Security Group

# App Server EC2 Outputs
app_server_2a_id         # Instance ID of App Server in us-east-2a
app_server_2b_id         # Instance ID of App Server in us-east-2b
app_server_2a_private_ip # Private IP address of App Server in us-east-2a
app_server_2b_private_ip # Private IP address of App Server in us-east-2b

# RDS Database Outputs
rds_endpoint             # Connection endpoint for RDS MySQL
rds_port                 # Database Port (3306)
rds_database_name        # Name of default database (exam_results)
rds_instance_id          # RDS Instance identifier
```
