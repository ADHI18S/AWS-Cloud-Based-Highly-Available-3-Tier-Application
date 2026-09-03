# Terraform Infrastructure as Code (IaC)

## 1. Overview
All infrastructure components previously deployed manually were codified into modular, reusable Terraform configuration files stored in the `terraform/` repository directory.

---

## 2. Directory Structure
```
terraform/
├── main.tf                 # Primary provider & module orchestrator
├── variables.tf            # Input variable declarations
├── outputs.tf              # Exported architecture endpoints
├── terraform.tfvars.example # Example variable parameter file
├── modules/
│   ├── vpc/                # Subnets, IGW, NAT Gateway, Route Tables
│   ├── security_groups/    # 3-tier Security Group chaining
│   ├── ec2_app/            # Launch Templates, ASGs, SSM Profiles
│   ├── rds/                # Multi-AZ RDS MySQL Database
│   └── alb/                # External & Internal Load Balancers
└── user_data/
    ├── app_server.sh       # Flask bootstrap script
    └── web_server.sh       # NGINX bootstrap script
```

---

## 3. Execution Commands

### Step 1: Initialize Terraform Working Directory
```bash
terraform init
```

### Step 2: Validate Syntax Integrity
```bash
terraform validate
```

### Step 3: Generate Execution Plan
```bash
terraform plan -out=tfplan
```

### Step 4: Apply Infrastructure Changes
```bash
terraform apply tfplan
```

### Step 5: Destroy Infrastructure (Teardown)
```bash
terraform destroy -auto-approve
```

---

## 4. Git Version Tagging
The verified Terraform codebase was committed and tagged in Git as version `vrsion1`:
```bash
git add terraform/
git commit -m "Add production-ready modularized Terraform IaC for 3-tier architecture"
git tag -a vrsion1 -m "Version 1.0 - Complete Terraform 3-Tier Infrastructure"
git push origin vrsion1
```
