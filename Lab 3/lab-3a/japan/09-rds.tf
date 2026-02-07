# RDS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group

# RDS Subnet Group
resource "aws_db_subnet_group" "edo_rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.edo_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

# RDS Instance
resource "aws_db_instance" "edo_rds01" {
  identifier        = "${local.name_prefix}-rds01"
  engine            = var.db_engine
  instance_class    = var.db_instance_class
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.edo_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.edo_rds_sg01.id]

  publicly_accessible = false
  skip_final_snapshot = true

  # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = {
    Name = "${local.name_prefix}-rds01"
  }
}