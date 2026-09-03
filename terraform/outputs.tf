# Network Outputs
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "The IPv4 CIDR block of the VPC"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public web subnets"
  value       = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = module.network.private_db_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.network.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway (in Public-Web-2a)"
  value       = module.network.nat_gateway_id
}

output "nat_eip_id" {
  description = "ID of the Elastic IP allocated for NAT Gateway"
  value       = module.network.nat_eip_id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.network.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "IDs of private application route tables"
  value       = module.network.private_app_route_table_ids
}

output "private_db_route_table_id" {
  description = "ID of private database route table"
  value       = module.network.private_db_route_table_id
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group"
  value       = module.network.db_subnet_group_name
}

# Security Group Outputs
output "external_alb_sg_id" {
  description = "ID of the External ALB Security Group"
  value       = module.security_groups.external_alb_sg_id
}

output "web_sg_id" {
  description = "ID of the Web Tier Security Group"
  value       = module.security_groups.web_sg_id
}

output "internal_alb_sg_id" {
  description = "ID of the Internal ALB Security Group"
  value       = module.security_groups.internal_alb_sg_id
}

output "app_sg_id" {
  description = "ID of the Application Tier Security Group"
  value       = module.security_groups.app_sg_id
}

output "db_sg_id" {
  description = "ID of the Database Tier Security Group"
  value       = module.security_groups.db_sg_id
}

# RDS Database Outputs
output "rds_endpoint" {
  description = "Connection endpoint for the RDS MySQL instance"
  value       = aws_db_instance.rds_mysql.endpoint
}

output "rds_port" {
  description = "Port number on which the RDS MySQL instance accepts connections"
  value       = aws_db_instance.rds_mysql.port
}

output "rds_database_name" {
  description = "Name of the default initial database"
  value       = aws_db_instance.rds_mysql.db_name
}

output "rds_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.rds_mysql.id
}

# EC2 App Server & SSM Outputs
output "app_server_2a_id" {
  description = "Instance ID of Private App Server 2a"
  value       = aws_instance.app_server_2a.id
}

output "app_server_2a_private_ip" {
  description = "Private IP address of App Server 2a"
  value       = aws_instance.app_server_2a.private_ip
}

output "app_ssm_role_name" {
  description = "IAM Role attached to App EC2 for AWS Systems Manager access"
  value       = aws_iam_role.app_ssm_role.name
}
