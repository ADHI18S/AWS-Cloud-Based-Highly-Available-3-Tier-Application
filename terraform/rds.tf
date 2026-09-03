# Minimal Amazon RDS MySQL Database Instance
resource "aws_db_instance" "rds_mysql" {
  identifier           = "college-results-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "gp2"
  storage_encrypted    = true
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  port                 = 3306
  multi_az             = var.db_multi_az
  publicly_accessible  = false
  db_subnet_group_name = module.network.db_subnet_group_name

  vpc_security_group_ids = [module.security_groups.db_sg_id]

  skip_final_snapshot = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db"
    }
  )
}
