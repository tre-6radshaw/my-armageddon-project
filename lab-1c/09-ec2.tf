############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: bos refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "bos_ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are your Wookiee toolbelt—tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "bos_ec2_ssm_attach" {
  role       = aws_iam_role.bos_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy" "bos_ec2_secrets_access" {
  name = "secrets-manager-bos-rds"
  role = aws_iam_role.bos_ec2_role01.id

  policy = file("${path.module}/1a_inline_policy.json")
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "bos_ec2_cw_attach" {
  role       = aws_iam_role.bos_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "bos_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.bos_ec2_role01.name
}

############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
resource "aws_instance" "bos_ec201" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.bos_public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.bos_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.bos_instance_profile01.name
  user_data              = file("${path.module}/1a_user_data.sh")

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}


############################################
# Move EC2 into PRIVATE subnet (no public IP)
############################################

# Explanation: bos hates exposure—private subnets keep your compute off the public holonet.
resource "aws_instance" "bos_ec201_private_bonus" {
  ami                   = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.bos_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.bos_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.bos_instance_profile01.name
  user_data              = file("${path.module}/1a_user_data.sh")

  # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
  # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.

  tags = {
    Name = "${local.bos_prefix}-ec201-private"
  }
}