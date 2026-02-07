# IAM Role
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role

resource "aws_iam_role" "gru_ec2_role01" {
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

# IAM Policy Creation - Secure Policy for EC2 to read the secret
resource "aws_iam_role_policy" "gru_ec2_secrets_access" {
  name = "secrets-manager-gru-rds"
  role = aws_iam_role.gru_ec2_role01.id

  policy = file("${path.module}/1a_inline_policy.json")
}


resource "aws_iam_role_policy_attachment" "gru_ec2_ssm_attach" {
  role       = aws_iam_role.gru_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# resource "aws_iam_role_policy_attachment" "gru_ec2_secrets_attach" {
#   role       = aws_iam_role.gru_ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
# }

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "gru_ec2_cw_attach" {
  role       = aws_iam_role.gru_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "gru_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.gru_ec2_role01.name
}