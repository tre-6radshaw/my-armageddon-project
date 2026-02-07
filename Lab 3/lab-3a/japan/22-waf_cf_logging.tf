# ############################################
# # WAFv2 Web ACL (Basic managed rules)
# ############################################

# # Explanation: WAF is the shield generator — it blocks the cheap blaster fire before it hits your ALB.
# resource "aws_wafv2_web_acl" "edo_waf01" {
#   count = var.enable_waf ? 1 : 0

#   name  = "${var.project_name}-waf01"
#   scope = "REGIONAL"

#   default_action {
#     allow {}
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${var.project_name}-waf01"
#     sampled_requests_enabled   = true
#   }

#   # Explanation: AWS managed rules are like hiring Rebel commandos — they’ve seen every trick.
#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "${var.project_name}-waf-common"
#       sampled_requests_enabled   = true
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-waf01"
#   }
# }

# ### Lab 2


# # Explanation: Attach the shield generator to the customs checkpoint — ALB is now protected.
# resource "aws_wafv2_web_acl_association" "edo_waf_assoc01" {
#   count = var.enable_waf ? 1 : 0

#   resource_arn = aws_lb.edo_alb01.arn
#   web_acl_arn  = aws_wafv2_web_acl.edo_waf01[0].arn
# }

############################################
# Bonus B - WAF Logging (CloudWatch Logs OR S3 OR Firehose)
# One destination per Web ACL, choose via var.waf_log_destination.
############################################

############################################
# Option 1: CloudWatch Logs destination
############################################

# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
# resource "aws_cloudwatch_log_group" "edo_waf_log_group01" {
#   provider = aws.useast1
#   count = var.waf_log_destination == "cloudwatch" ? 1 : 0

#   # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
#   name              = "aws-waf-logs-${var.project_name}-webacl01"
#   retention_in_days = var.waf_log_retention_days

#   tags = {
#     Name = "${var.project_name}-waf-log-group01"
#   }
# }

# # Explanation: This wire connects the shield generator to the black box—WAF -> CloudWatch Logs.
# resource "aws_wafv2_web_acl_logging_configuration" "edo_waf_logging01" {
#   provider = aws.useast1
#   count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

#   resource_arn = aws_wafv2_web_acl.edo_cf_waf01.arn
#   log_destination_configs = [
#     aws_cloudwatch_log_group.edo_waf_log_group01[0].arn
#   ]

#   # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
#   # redacted_fields { ... }

#   depends_on = [aws_wafv2_web_acl.edo_cf_waf01]
# }

###Lab 2