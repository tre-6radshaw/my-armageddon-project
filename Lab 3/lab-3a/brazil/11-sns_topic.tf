############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "gru_sns_topic01" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "gru_sns_sub01" {
  topic_arn = aws_sns_topic.gru_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}