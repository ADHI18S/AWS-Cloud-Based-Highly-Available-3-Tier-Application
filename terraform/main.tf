# 1. Network Module (VPC, Subnets, Gateways, Route Tables, DB Subnet Group)
module "network" {
  source = "./modules/network"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  single_nat_gateway       = var.single_nat_gateway
  tags                     = local.common_tags
}

# 2. Security Groups Module (Web, App, DB Security Groups)
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id        = module.network.vpc_id
  name_prefix   = local.name_prefix
  admin_ip_cidr = var.admin_ip_cidr
  tags          = local.common_tags
}
