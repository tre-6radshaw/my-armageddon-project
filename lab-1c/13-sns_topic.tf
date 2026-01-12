############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "bos_sns_topic01" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "bos_sns_sub01" {
  topic_arn = aws_sns_topic.bos_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# SNS Topic Subscription (triggers Lambda on alarm)
resource "aws_sns_topic_subscription" "bos_ir_lambda_sub01" {
  topic_arn = aws_sns_topic.bos_sns_topic01.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bos_ir_lambda01.arn
}

# Allow SNS to invoke the Lambda
resource "aws_lambda_permission" "bos_allow_sns_invoke01" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bos_ir_lambda01.function_name
  principal     = "sns.amazonaws.com"  # Fixed: quoted
  source_arn    = aws_sns_topic.bos_sns_topic01.arn
}