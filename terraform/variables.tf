variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "college-results"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC (from vpc-setup.md)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones for high availability deployment"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for Public Web subnets (from vpc-setup.md)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for Private App subnets (from vpc-setup.md)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for Private DB subnets (from vpc-setup.md)"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "single_nat_gateway" {
  description = "If true (default), deploy a single NAT Gateway in Public-Web-2a shared across private subnets for AWS cost optimization."
  type        = bool
  default     = true
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR block for SSH access (replaces YOUR_IP/32 from security-groups.json)"
  type        = string
  default     = "0.0.0.0/0"
}

# RDS Database Variables
variable "db_username" {
  description = "Master username for RDS MySQL database"
  type        = string
  default     = "collegeuser"
}

variable "db_password" {
  description = "Master password for RDS MySQL database (provided at runtime)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name created on initialization"
  type        = string
  default     = "college_results"
}

variable "db_instance_class" {
  description = "Minimal, cost-effective RDS DB instance class suitable for training"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Deploy multi-AZ RDS. Set false (default) for minimal single-instance training cost."
  type        = bool
  default     = false
}

# EC2 App Server Variables
variable "ami_id" {
  description = "AMI ID for App Server EC2 instances. If empty, the latest Ubuntu 22.04 LTS AMI will be fetched dynamically."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for App Servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional SSH Key Pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "application_repo" {
  description = "Optional Git repository URL to clone in user_data"
  type        = string
  default     = ""
}
