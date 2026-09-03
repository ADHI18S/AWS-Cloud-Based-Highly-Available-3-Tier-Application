output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The IPv4 CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.gw.id
}

output "nat_gateway_id" {
  description = "The ID of the single NAT Gateway in Public-Web-2a"
  value       = aws_nat_gateway.nat[0].id
}

output "nat_eip_id" {
  description = "The ID of the Elastic IP allocated for the single NAT Gateway"
  value       = aws_eip.nat[0].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "IDs of the private application route tables"
  value       = aws_route_table.private_app[*].id
}

output "private_db_route_table_id" {
  description = "ID of the private database route table"
  value       = aws_route_table.private_db.id
}

output "db_subnet_group_name" {
  description = "The name of the RDS DB subnet group"
  value       = aws_db_subnet_group.db_subnet_group.name
}

output "db_subnet_group_id" {
  description = "The ID of the RDS DB subnet group"
  value       = aws_db_subnet_group.db_subnet_group.id
}
