variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for security group names"
  type        = string
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR block for SSH access (default: 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
