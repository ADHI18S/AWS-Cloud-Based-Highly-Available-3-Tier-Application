# 1. External ALB Security Group (external_alb_sg)
resource "aws_security_group" "external_alb_sg" {
  name        = "${var.name_prefix}-external-alb-sg"
  description = "Security group for External Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound HTTP from anywhere
  ingress {
    description      = "Allow HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    description      = "Allow HTTPS from internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Outbound all traffic
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-external-alb-sg"
    }
  )
}

# 2. Web Tier Security Group (web_sg)
resource "aws_security_group" "web_sg" {
  name        = "${var.name_prefix}-web-sg"
  description = "Security group for Web EC2 instances (NGINX)"
  vpc_id      = var.vpc_id

  # Inbound HTTP (80) from External ALB Security Group ONLY
  ingress {
    description     = "Allow HTTP traffic from External ALB ONLY"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]
  }

  # SSH Access from Admin CIDR
  ingress {
    description = "SSH Access from Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Outbound all traffic
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-web-sg"
    }
  )
}

# 3. Internal ALB Security Group (internal_alb_sg)
resource "aws_security_group" "internal_alb_sg" {
  name        = "${var.name_prefix}-internal-alb-sg"
  description = "Security group for Internal Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound Port 8000 from Web Tier Security Group ONLY
  ingress {
    description     = "Allow HTTP traffic from Web Tier Security Group ONLY"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Outbound all traffic
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-internal-alb-sg"
    }
  )
}

# 4. Application Tier Security Group (app_sg)
resource "aws_security_group" "app_sg" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for Application Tier (Flask API)"
  vpc_id      = var.vpc_id

  # Inbound Port 8000 from Internal ALB Security Group ONLY
  ingress {
    description     = "Allow HTTP traffic from Internal ALB Security Group ONLY"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }

  # SSH Access from Admin CIDR
  ingress {
    description = "SSH Access from Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Outbound all traffic
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-app-sg"
    }
  )
}

# 5. Database Tier Security Group (db_sg)
resource "aws_security_group" "db_sg" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for Database Tier (RDS MySQL)"
  vpc_id      = var.vpc_id

  # Inbound MySQL (3306) from Application Tier Security Group ONLY
  ingress {
    description     = "Allow MySQL traffic from App Tier Security Group ONLY"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  # Outbound all traffic
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-sg"
    }
  )
}
