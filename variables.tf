# variable "ca_cert_identifier" {
#   description = "Specifies the identifier of the CA certificate for the DB instance"
#   type        = string
#   default     = "rds-ca-rsa4096-g1"
# }

# variable "snapshot_identifier" {
#   description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
#   type        = string
#   default     = null
# }

# variable "skip_final_snapshot" {
#   description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted"
#   type        = bool
#   default     = false
# }

# variable "identifier" {
#   description = "The name of the RDS instance"
#   type        = string
# }
