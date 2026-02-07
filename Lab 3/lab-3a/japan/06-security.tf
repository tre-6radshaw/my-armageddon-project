# Security Groups
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule

# EC2 Security Group
resource "aws_security_group" "edo_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.edo_vpc01.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

### EC2 SG Ingress Rule (Bonus B) ###
resource "aws_vpc_security_group_ingress_rule" "edo_ec2_ingress_from_alb01" {
  security_group_id            = aws_security_group.edo_ec2_sg01.id
  referenced_security_group_id = aws_security_group.edo_alb_sg01.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_traffic_ipv4" {
  security_group_id = aws_security_group.edo_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# RDS Security Group
resource "aws_security_group" "edo_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.edo_vpc01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

# RDS SG Rules
resource "aws_vpc_security_group_ingress_rule" "edo_rds_mysql" {
  security_group_id            = aws_security_group.edo_rds_sg01.id
  referenced_security_group_id = aws_security_group.edo_ec2_sg01.id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  description = "Allow MySQL access only from app tier EC2 instances"
}

### Lab 3a RDS SG - inbound access from Brazil VPC CIDR
resource "aws_vpc_security_group_ingress_rule" "gru_to_edo_rds_mysql" {
  security_group_id = aws_security_group.edo_rds_sg01.id
  cidr_ipv4         = var.brazil_vpc_cidr

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  description = "Allow MySQL access only from app tier EC2 instances"
}


resource "aws_vpc_security_group_egress_rule" "rds_all_traffic_ipv4" {
  security_group_id = aws_security_group.edo_rds_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols and ports
  description       = "Allow all outbound traffic"
}

############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—Chewbacca posts a Wookiee at every airlock.
resource "aws_security_group" "edo_vpce_sg01" {
  name        = "${local.edo_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.edo_vpc01.id

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  tags = {
    Name = "${local.edo_prefix}-vpce-sg01"
  }
}

# VPC Interface SG Rules
resource "aws_vpc_security_group_ingress_rule" "edo_vpce_ingress" {
  security_group_id            = aws_security_group.edo_vpce_sg01.id
  referenced_security_group_id = aws_security_group.edo_ec2_sg01.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  description = "Allow EC2 SG access only for 443"
}


resource "aws_vpc_security_group_egress_rule" "vpce_all_traffic_ipv4" {
  security_group_id = aws_security_group.edo_vpce_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols and ports
  description       = "Allow all outbound traffic"
}

### Bonus B
############################################
# Security Group: ALB
############################################

# Explanation: The ALB SG is the blast shield — only allow what the Rebellion needs (80/443).
resource "aws_security_group" "edo_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.edo_vpc01.id

  # TODO: students add inbound 80/443 from 0.0.0.0/0
  # TODO: students set outbound to target group port (usually 80) to private targets

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

### Adding the Inbound (80/443) and Outbound Rules for ALB SG (Target Group 80)
resource "aws_vpc_security_group_ingress_rule" "edo_alb_ingres_80" {
  security_group_id = aws_security_group.edo_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

### Lab 1
# resource "aws_vpc_security_group_ingress_rule" "edo_alb_ingres_443" {
#   security_group_id = aws_security_group.edo_alb_sg01.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

### Updated for Lab 2a
resource "aws_vpc_security_group_ingress_rule" "edo_alb_ingres_443" {
  security_group_id = aws_security_group.edo_alb_sg01.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.edo_cf_origin_facing01.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "edo_alb_egress" {
  security_group_id = aws_security_group.edo_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}