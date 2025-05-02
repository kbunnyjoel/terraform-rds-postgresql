locals {
  name = "complete-postgresql"

  vpc_cidr         = "10.0.0.0/16"
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  kms_key_alias_id = data.aws_kms_alias.rds_key_id.id

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-rds"
  }
}
