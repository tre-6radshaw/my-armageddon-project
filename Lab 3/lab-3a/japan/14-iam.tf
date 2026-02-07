############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: edo doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "edo_leastpriv_read_params01" {
  name        = "${local.name_prefix}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /edo/db/*"

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
          "arn:aws:ssm:${data.aws_region.edo_region01.region}:${data.aws_caller_identity.edo_self01.account_id}:parameter/edo/db/*"
        ]
      }
    ]
  })
}

# Explanation: edo only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "edo_leastpriv_read_secret01" {
  name        = "${local.name_prefix}-lp-secrets-read01"
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
        Resource = local.edo_secret_arn_guess
      }
    ]
  })
}

# Explanation: When the Falcon logs scream, this lets edo ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "edo_leastpriv_cwlogs01" {
  name        = "${local.name_prefix}-lp-cwlogs01"
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
          "${aws_cloudwatch_log_group.edo_log_group01.arn}:*"
        ]
      }
    ]
  })
}

# Explanation: Attach the scoped policies—edo loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "edo_attach_lp_params01" {
  role       = aws_iam_role.edo_ec2_role01.name
  policy_arn = aws_iam_policy.edo_leastpriv_read_params01.arn
}

resource "aws_iam_role_policy_attachment" "edo_attach_lp_secret01" {
  role       = aws_iam_role.edo_ec2_role01.name
  policy_arn = aws_iam_policy.edo_leastpriv_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "edo_attach_lp_cwlogs01" {
  role       = aws_iam_role.edo_ec2_role01.name
  policy_arn = aws_iam_policy.edo_leastpriv_cwlogs01.arn
}