############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: bos doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "bos_leastpriv_read_params01" {
  name        = "${local.bos_prefix}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.bos_region01.region}:${data.aws_caller_identity.bos_self01.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })
}

# Explanation: bos only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "bos_leastpriv_read_secret01" {
  name        = "${local.bos_prefix}-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.bos_secret_arn_guess
      }
    ]
  })
}

# Explanation: When the Falcon logs scream, this lets bos ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "bos_leastpriv_cwlogs01" {
  name        = "${local.bos_prefix}-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.bos_log_group01.arn}:*"
        ]
      }
    ]
  })
}

# Explanation: Attach the scoped policies—bos loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "bos_attach_lp_params01" {
  role       = aws_iam_role.bos_ec2_role01.name
  policy_arn = aws_iam_policy.bos_leastpriv_read_params01.arn
}

resource "aws_iam_role_policy_attachment" "bos_attach_lp_secret01" {
  role       = aws_iam_role.bos_ec2_role01.name
  policy_arn = aws_iam_policy.bos_leastpriv_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "bos_attach_lp_cwlogs01" {
  role       = aws_iam_role.bos_ec2_role01.name
  policy_arn = aws_iam_policy.bos_leastpriv_cwlogs01.arn
}