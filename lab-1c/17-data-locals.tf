############################################
# Bonus A - Data + Locals
############################################

# Explanation: bos wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "bos_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "bos_region01" {}

locals {
  # Explanation: Name prefix is the roar that echoes through every tag.
  bos_prefix = var.project_name

  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  bos_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.bos_region01.region}:${data.aws_caller_identity.bos_self01.account_id}:secret:${local.bos_prefix}/rds/mysql*"
}