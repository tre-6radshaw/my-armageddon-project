# Explanation: Outputs are your mission report—what got built and where to find it.
output "edo_vpc_id" {
  value = aws_vpc.edo_vpc01.id
}

output "edo_public_subnet_ids" {
  value = aws_subnet.edo_public_subnets[*].id
}

output "edo_private_subnet_ids" {
  value = aws_subnet.edo_private_subnets[*].id
}

# output "edo_ec2_instance_id" {
#   value = aws_instance.edo_ec201_private_bonus.id
# }



output "edo_sns_topic_arn" {
  value = aws_sns_topic.edo_sns_topic01.arn
}

output "edo_log_group_name" {
  value = aws_cloudwatch_log_group.edo_log_group01.name
}

#Bonus-A outputs (append to outputs.tf)

# Explanation: These outputs prove Chewbacca built private hyperspace lanes (endpoints) instead of public chaos.
output "edo_vpce_ssm_id" {
  value = aws_vpc_endpoint.edo_vpce_ssm01.id
}

output "edo_vpce_logs_id" {
  value = aws_vpc_endpoint.edo_vpce_logs01.id
}

output "edo_vpce_secrets_id" {
  value = aws_vpc_endpoint.edo_vpce_secrets01.id
}

output "edo_vpce_s3_id" {
  value = aws_vpc_endpoint.edo_vpce_s3_gw01.id
}

# output "edo_private_ec2_instance_id_bonus" {
#   value = aws_instance.edo_ec201_private_bonus.id
# }

# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
output "edo_alb_dns_name" {
  value = aws_lb.edo_alb01.dns_name
}

output "edo_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "edo_target_group_arn" {
  value = aws_lb_target_group.edo_tg01.arn
}

output "edo_acm_cert_arn" {
  value = aws_acm_certificate.edo_acm_cert01.arn
}

# output "edo_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.edo_cf_waf01.arn : null
# }

output "edo_dashboard_name" {
  value = aws_cloudwatch_dashboard.edo_dashboard01.dashboard_name
}

output "edo_route53_zone_id" {
  value = local.edo_zone_id
}

output "edo_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "edo_apex_url_https" {
  value = "https://${var.domain_name}"
}

output "edo_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.edo_alb_logs_bucket01[0].bucket : null
}

output "edo_waf_log_destination" {
  value = var.waf_log_destination
}

# output "edo_waf_cw_log_group_name" {
#   value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.edo_waf_log_group01[0].name : null
# }

output "current_growl_secret" {
  value     = random_password.edo_origin_header_value01.result
  sensitive = true
}

# Output for reference (optional)
output "edo_tgw_id" {
  value       = aws_ec2_transit_gateway.edo_tgw01.id
  description = "Tokyo Transit Gateway ID"
}

output "tokyo_vpc_cidr" {
  value = var.vpc_cidr
}

output "edo_rds_endpoint" {
  value = aws_db_instance.edo_rds01.address
}

output "random_pw" {
  value = random_password.edo_origin_header_value01.result
  sensitive = true
}