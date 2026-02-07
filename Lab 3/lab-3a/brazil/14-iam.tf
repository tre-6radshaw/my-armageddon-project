############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: gru doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
# resource "aws_iam_policy" "gru_leastpriv_read_params01" {
#   name        = "${local.gru_prefix}-lp-ssm-read01"
#   description = "Least-privilege read for SSM Parameter Store under /gru/db/*"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "ReadLabDbParams"
#         Effect = "Allow"
#         Action = [
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ]
#         Resource = [
#           "arn:aws:ssm:${data.aws_region.gru_region01.region}:${data.aws_caller_identity.gru_self01.account_id}:parameter/gru/db/*"
#         ]
#       }
#     ]
#   })
# }

# Explanation: gru only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
# resource "aws_iam_policy" "gru_leastpriv_read_secret01" {
#   name        = "${local.gru_prefix}-lp-secrets-read01"
#   description = "Least-privilege read for the lab DB secret"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "ReadOnlyLabSecret"
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret"
#         ]
#         Resource = local.gru_secret_arn_guess
#       }
#     ]
#   })
# }

# Explanation: When the Falcon logs scream, this lets gru ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "gru_leastpriv_cwlogs01" {
  name        = "${local.gru_prefix}-lp-cwlogs01"
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
          "${aws_cloudwatch_log_group.gru_log_group01.arn}:*"
        ]
      }
    ]
  })
}

# Explanation: Attach the scoped policies—gru loves power, but only the safe kind.
# resource "aws_iam_role_policy_attachment" "gru_attach_lp_params01" {
#   role       = aws_iam_role.gru_ec2_role01.name
#   policy_arn = aws_iam_policy.gru_leastpriv_read_params01.arn
# }

# resource "aws_iam_role_policy_attachment" "gru_attach_lp_secret01" {
#   role       = aws_iam_role.gru_ec2_role01.name
#   policy_arn = aws_iam_policy.gru_leastpriv_read_secret01.arn
# }

resource "aws_iam_role_policy_attachment" "gru_attach_lp_cwlogs01" {
  role       = aws_iam_role.gru_ec2_role01.name
  policy_arn = aws_iam_policy.gru_leastpriv_cwlogs01.arn
}