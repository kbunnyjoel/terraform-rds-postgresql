

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "git::https://github.com/kbunnyjoel/terraform-rds-postgresql-module.git?ref=v1.1"

  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                   = "postgres"
  engine_version           = "14"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
#   family                   = "postgres14" # DB parameter group
#   major_engine_version     = "14"         # DB option group
  instance_class           = "db.t4g.large"
  storage_type             = "gp3"
  storage_encrypted        = true

  allocated_storage     = 20
  max_allocated_storage = 100

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name           = "completePostgresql"
  username          = "complete_postgresql"
  password          = "complete_postgresql_password"
  port              = 5432
  kms_key_id        = local.kms_key_alias_id
  apply_immediately = true

  # Setting manage_master_user_password_rotation to false after it
  # has previously been set to true disables automatic rotation
  # however using an initial value of false (default) does not disable
  # automatic rotation and rotation will be handled by RDS.
  # manage_master_user_password_rotation allows users to configure
  # a non-default schedule and is not meant to disable rotation
  # when initially creating / enabling the password management feature
  #   manage_master_user_password_rotation              = true
  #   master_user_password_rotate_immediately           = false
  #   master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az                  = true
  db_subnet_group_name      = module.vpc.database_subnet_group
  vpc_security_group_ids    = [module.security_group.security_group_id]
  ca_cert_identifier        = "rds-ca-rsa4096-g1"
  snapshot_identifier       = resource.random_id.snapshot_identifier.keepers.snapshot_identifier
  copy_tags_to_snapshot     = true
#   final_snapshot_identifier = "${local.name}-final-snapshot"


  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period  = 1
  skip_final_snapshot      = true
  deletion_protection      = false
  delete_automated_backups = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "RDS-PostgreSQL-EnhancedMonitoringRole"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"
  performance_insights_kms_key_id       = resource.aws_kms_alias.performance_insights_alias.target_key_id

#   parameters = [
#     {
#       name  = "autovacuum"
#       value = 1
#     },
#     {
#       name  = "client_encoding"
#       value = "utf8"
#     }
#   ]

  tags = local.tags
#   db_option_group_tags = {
#     "Sensitive" = "low"
#   }
#   db_parameter_group_tags = {
#     "Sensitive" = "low"
#   }
  cloudwatch_log_group_tags = {
    "Sensitive" = "high"
  }
}

module "kms" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.0"
  description = "KMS key for cross region automated backups replication"

  # Aliases
  aliases                    = [local.name]
  aliases_use_name_prefix = true

  key_owners = [data.aws_caller_identity.current.arn]

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true
  enable_nat_gateway           = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Complete PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  # egress
  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Egress to AWS Lambda VPC"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}

resource "random_id" "snapshot_identifier" {

  keepers = {
    id                  = local.name
    snapshot_identifier = "test-snapshot-db-identifier"
  }

  byte_length = 4
}

resource "aws_kms_key" "performance_insights_key" {
  description             = "KMS key for RDS PostgreSQL Performance Insights encryption"
  deletion_window_in_days = 30
#   enable_key_rotation     = true

  tags = {
    Name        = "performance-insights-key"
    Environment = "dev"
  }
}

# Create an alias for the KMS key
resource "aws_kms_alias" "performance_insights_alias" {
  name          = "alias/performance-insights-key"
  target_key_id = aws_kms_key.performance_insights_key.id
}
