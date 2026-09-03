# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

# 2. Public Subnets (Web Tier / External ALB)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "Public-Web-${element(split("-", var.availability_zones[count.index % length(var.availability_zones)]), 2)}"
      Tier = "Public-Web"
    }
  )
}

# 3. Private Application Subnets (Flask API Tier / Internal ALB)
resource "aws_subnet" "private_app" {
  count                   = length(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "Private-App-${element(split("-", var.availability_zones[count.index % length(var.availability_zones)]), 2)}"
      Tier = "Private-App"
    }
  )
}

# 4. Private Database Subnets (RDS MySQL Tier)
resource "aws_subnet" "private_db" {
  count                   = length(var.private_db_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "Private-DB-${element(split("-", var.availability_zones[count.index % length(var.availability_zones)]), 2)}"
      Tier = "Private-DB"
    }
  )
}

# 5. Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# 6. Elastic IP(s) for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = var.single_nat_gateway ? "${var.name_prefix}-eip" : "${var.name_prefix}-eip-${element(split("-", var.availability_zones[count.index]), 2)}"
    }
  )

  depends_on = [aws_internet_gateway.gw]
}

# 7. NAT Gateway(s) in Public Subnet
resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = var.single_nat_gateway ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${element(split("-", var.availability_zones[count.index]), 2)}"
    }
  )

  depends_on = [aws_internet_gateway.gw]
}

# 8. Public Route Table & Internet Route
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

# 9. Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 10. Private Application Route Table(s) & NAT Routes
resource "aws_route_table" "private_app" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = var.single_nat_gateway ? "${var.name_prefix}-private-app-rt" : "${var.name_prefix}-private-app-rt-${element(split("-", var.availability_zones[count.index]), 2)}"
    }
  )
}

# 11. Private Application Route Table Associations
resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private_app[0].id : aws_route_table.private_app[count.index].id
}

# 12. Private Database Route Table (Isolated: Local traffic only, NO internet/NAT route)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-db-rt"
    }
  )
}

# 13. Private Database Route Table Associations
resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}

# 14. DB Subnet Group for RDS MySQL
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "college-results-db-subnet-group"
  subnet_ids  = aws_subnet.private_db[*].id
  description = "Database Subnet Group for RDS MySQL Multi-AZ deployment"

  tags = merge(
    var.tags,
    {
      Name = "college-results-db-subnet-group"
    }
  )
}
