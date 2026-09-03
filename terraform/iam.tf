# IAM Role for AWS Systems Manager (SSM) Session Manager Access
resource "aws_iam_role" "app_ssm_role" {
  name = "${local.name_prefix}-app-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-ssm-role"
    }
  )
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "app_ssm_attachment" {
  role       = aws_iam_role.app_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for EC2 App Server
resource "aws_iam_instance_profile" "app_ssm_profile" {
  name = "${local.name_prefix}-app-ssm-profile"
  role = aws_iam_role.app_ssm_role.name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-ssm-profile"
    }
  )
}
