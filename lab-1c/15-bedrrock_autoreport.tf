############################################
# Bonus G - Bedrock Auto Incident Report Pipeline (SNS -> Lambda -> S3)
############################################

# Explanation: This bucket is bos’s incident archive—postmortems go here, not into Slack void.
resource "aws_s3_bucket" "bos_ir_reports_bucket01" {
  bucket = "${var.project_name}-ir-reports-${data.aws_caller_identity.bos_self01.account_id}"

  tags = {
    Name = "${var.project_name}-ir-reports-bucket01"
  }
}

# Explanation: bos blocks public access—incident reports are not fan fiction for the public internet.
resource "aws_s3_bucket_public_access_block" "bos_ir_reports_pab01" {
  bucket                  = aws_s3_bucket.bos_ir_reports_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: This role is the droid brain—Lambda assumes it to collect evidence and call Bedrock.
resource "aws_iam_role" "bos_ir_lambda_role01" {
  name = "${var.project_name}-ir-lambda-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: bos grants the minimum needed—logs, S3, SSM, Secrets, CloudWatch, and Bedrock invoke.
resource "aws_iam_policy" "bos_ir_lambda_policy01" {
  name = "${var.project_name}-ir-lambda-policy01"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs Insights queries
      {
        Effect = "Allow",
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      # CloudWatch alarm/metrics read
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ],
        Resource = "*"
      },
      # Parameter Store
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.bos_self01.account_id}:parameter/lab/db/*"
      },
      # Secrets Manager
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.bos_self01.account_id}:secret:${var.project_name}/rds/mysql*"
      },
      # S3 report write
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.bos_ir_reports_bucket01.arn,
          "${aws_s3_bucket.bos_ir_reports_bucket01.arn}/*"
        ]
      },
      # Bedrock invoke
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "*"
      }
    ]
  })
}

# Explanation: Attach the policy—bos equips the Lambda like a proper Wookiee engineer.
resource "aws_iam_role_policy_attachment" "bos_ir_lambda_attach01" {
  role       = aws_iam_role.bos_ir_lambda_role01.name
  policy_arn = aws_iam_policy.bos_ir_lambda_policy01.arn
}

# Explanation: Basic Lambda logging—because even droids need diaries.
resource "aws_iam_role_policy_attachment" "bos_ir_lambda_basiclogs01" {
  role       = aws_iam_role.bos_ir_lambda_role01.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Explanation: The Lambda itself—bos’s incident scribe that writes your postmortem while you fight fires.
resource "aws_lambda_function" "bos_ir_lambda01" {
  function_name = "${var.project_name}-ir-reporter01"
  role          = aws_iam_role.bos_ir_lambda_role01.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  # TODO: students provide a real zip file path
  filename         = "lambda_ir_reporter.zip"
  source_code_hash = filebase64sha256("lambda_ir_reporter.zip")

  environment {
    variables = {
      REPORT_BUCKET        = aws_s3_bucket.bos_ir_reports_bucket01.bucket
      APP_LOG_GROUP        = "/aws/ec2/${var.project_name}-rds-app"
      WAF_LOG_GROUP        = "aws-waf-logs-${var.project_name}-webacl01"
      SECRET_ID            = "${var.project_name}/rds/mysql"
      SSM_PARAM_PATH       = "/lab/db/"
      BEDROCK_MODEL_ID     = "upstage-solar-pro-quantized" # TODO: students choose a Bedrock text model id available in their account/region
      SNS_TOPIC_ARN        = aws_sns_topic.bos_sns_topic01.arn
    }
  }
}



