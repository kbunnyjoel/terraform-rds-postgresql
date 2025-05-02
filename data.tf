data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_kms_alias" "rds_key_id" {
    name = "alias/${local.name}"
}
