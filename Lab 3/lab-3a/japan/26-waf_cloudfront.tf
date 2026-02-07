# # Explanation: The shield generator moves to the edge — CloudFront WAF blocks nonsense before it hits your VPC.
# resource "aws_wafv2_web_acl" "edo_cf_waf01" {
#   provider = aws.useast1
#   name  = "${var.project_name}-cf-waf01"
#   scope = "CLOUDFRONT"

#   default_action {
#     allow {}
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${var.project_name}-cf-waf01"
#     sampled_requests_enabled   = true
#   }

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
#       metric_name                = "${var.project_name}-cf-waf-common"
#       sampled_requests_enabled   = true
#     }
#   }
# }