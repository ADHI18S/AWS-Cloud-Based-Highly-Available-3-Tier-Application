# Data Source: Fetch Latest Ubuntu 22.04 LTS AMI if var.ami_id is not specified
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Private App Server 2a (AZ: us-east-2a, Subnet: Private-App-2a)
resource "aws_instance" "app_server_2a" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = module.network.private_app_subnet_ids[0]
  vpc_security_group_ids      = [module.security_groups.app_sg_id]
  associate_public_ip_address = false

  # Systems Manager IAM Instance Profile for Session Manager Access
  iam_instance_profile = aws_iam_instance_profile.app_ssm_profile.name

  # User Data script passing RDS connection details & database credentials
  user_data = templatefile("${path.module}/user_data/app_server.sh", {
    db_host     = split(":", aws_db_instance.rds_mysql.endpoint)[0]
    db_port     = aws_db_instance.rds_mysql.port
    db_user     = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "college-results-app-2a"
      Project     = "college-results"
      Environment = "prod"
      Tier        = "app"
    }
  )
}
