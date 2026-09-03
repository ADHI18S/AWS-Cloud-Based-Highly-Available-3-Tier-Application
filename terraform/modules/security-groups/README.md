# Security Groups Module

This module provisions 5 security groups chained together to implement strict least-privilege isolation:

```
Internet ➔ external_alb_sg ➔ web_sg ➔ internal_alb_sg ➔ app_sg ➔ db_sg
```

## Created Security Groups

1. **external_alb_sg**: Permits HTTP (80) & HTTPS (443) from `0.0.0.0/0`.
2. **web_sg**: Permits HTTP (80) **only from `external_alb_sg`**, SSH (22) from admin CIDR.
3. **internal_alb_sg**: Permits Port 8000 **only from `web_sg`**.
4. **app_sg**: Permits Port 8000 **only from `internal_alb_sg`**, SSH (22) from admin CIDR.
5. **db_sg**: Permits MySQL (3306) **only from `app_sg`**.

## Usage

```hcl
module "security_groups" {
  source        = "./modules/security-groups"
  vpc_id        = module.network.vpc_id
  name_prefix   = "college-results-prod"
  admin_ip_cidr = "0.0.0.0/0"
  tags          = local.common_tags
}
```
