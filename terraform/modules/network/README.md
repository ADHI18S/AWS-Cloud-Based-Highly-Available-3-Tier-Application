# Network Module

This module provisions the network infrastructure for the 3-Tier College Exam Result Website on AWS.

## Resources Created

- **AWS VPC**: 10.0.0.0/16 with DNS support and DNS hostnames enabled
- **Public Subnets**: 2 subnets across 2 AZs (10.0.1.0/24 in us-east-2a, 10.0.2.0/24 in us-east-2b)
- **Private App Subnets**: 2 subnets across 2 AZs (10.0.3.0/24 in us-east-2a, 10.0.4.0/24 in us-east-2b)
- **Private DB Subnets**: 2 subnets across 2 AZs (10.0.5.0/24 in us-east-2a, 10.0.6.0/24 in us-east-2b)
- **Internet Gateway**: Attached to VPC for public Internet access
- **NAT Gateway & EIP**: Single NAT Gateway deployed in `Public-Web-2a` for cost-optimized outbound private app access
- **Route Tables**: Public (`0.0.0.0/0 -> IGW`), Private App (`0.0.0.0/0 -> NAT GW in Public-Web-2a`), and Private DB (Isolated local-only)
- **DB Subnet Group**: `college-results-db-subnet-group` containing private DB subnets

## Usage

```hcl
module "network" {
  source                   = "./modules/network"
  name_prefix              = "college-results-prod"
  vpc_cidr                 = "10.0.0.0/16"
  availability_zones       = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  private_db_subnet_cidrs  = ["10.0.5.0/24", "10.0.6.0/24"]
  single_nat_gateway       = true
  tags                     = local.common_tags
}
```
