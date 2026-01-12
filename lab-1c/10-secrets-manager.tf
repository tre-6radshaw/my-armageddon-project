############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is bos’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "bos_db_endpoint_param" {
  name  = "/bos/db/endpoint"
  type  = "String"
  value = aws_db_instance.bos_rds01.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "bos_db_port_param" {
  name  = "/bos/db/port"
  type  = "String"
  value = tostring(aws_db_instance.bos_rds01.port)

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "bos_db_name_param" {
  name  = "/bos/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is bos’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "bos_db_secret01" {
  name = "${local.name_prefix}/rds/mysql"
  recovery_window_in_days = 0
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "bos_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.bos_db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.bos_rds01.address
    port     = aws_db_instance.bos_rds01.port
    dbname   = var.db_name
  })
}