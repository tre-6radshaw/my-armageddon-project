# Explanation: EC2 SG is bos’s bodyguard—only let in what you mean to.
resource "aws_security_group" "bos_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.bos_vpc01.id

  # TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
  # TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bos_ec2_http" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc_security_group_ingress_rule" "bos_ssh" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "${chomp(data.http.myip.response_body)}/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_traffic_ipv4" {
  security_group_id = aws_security_group.bos_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "bos_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.bos_vpc01.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group.bos_ec2_sg01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

# Ingress: Allow MySQL only from the EC2 app server's security group
resource "aws_vpc_security_group_ingress_rule" "bos_rds_mysql" {
  security_group_id            = aws_security_group.bos_rds_sg01.id
  referenced_security_group_id = aws_security_group.bos_ec2_sg01.id # ← This points to your EC2 SG

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  description = "Allow MySQL access only from app tier EC2 instances"
}

# Egress: Remains unchanged (allow all outbound)
resource "aws_vpc_security_group_egress_rule" "rds_all_traffic_ipv4" {
  security_group_id = aws_security_group.bos_rds_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols and ports
  description       = "Allow all outbound traffic"
}


############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—bos posts a Wookiee at every airlock.
resource "aws_security_group" "bos_vpce_sg01" {
  name        = "${local.bos_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.bos_vpc01.id

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  tags = {
    Name = "${local.bos_prefix}-vpce-sg01"
  }
}



############################################
# Security Group: ALB
############################################

# Explanation: The ALB SG is the blast shield — only allow what the Rebellion needs (80/443).
resource "aws_security_group" "bos_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.bos_vpc01.id

  # TODO: students add inbound 80/443 from 0.0.0.0/0
  # TODO: students set outbound to target group port (usually 80) to private targets

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

# Explanation: bos only opens the hangar door — allow ALB -> EC2 on app port (e.g., 80).
resource "aws_security_group_rule" "bos_ec2_ingress_from_alb01" {
  type                     = "ingress"
  security_group_id        = aws_security_group.bos_ec2_sg01.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bos_alb_sg01.id

  # TODO: students ensure EC2 app listens on this port (or change to 8080, etc.)
}

