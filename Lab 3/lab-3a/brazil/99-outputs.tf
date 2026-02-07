# Explanation: Outputs are your mission report—what got built and where to find it.
output "gru_vpc_id" {
  value = aws_vpc.gru_vpc01.id
}

output "gru_public_subnet_ids" {
  value = aws_subnet.gru_public_subnets[*].id
}

output "gru_private_subnet_ids" {
  value = aws_subnet.gru_private_subnets[*].id
}

# output "gru_ec2_instance_id" {
#   value = aws_instance.gru_ec201_private_bonus.id
# }

# output "gru_rds_endpoint" {
#   value = aws_db_instance.gru_rds01.address
# }

output "gru_sns_topic_arn" {
  value = aws_sns_topic.gru_sns_topic01.arn
}

output "gru_log_group_name" {
  value = aws_cloudwatch_log_group.gru_log_group01.name
}

#Bonus-A outputs (append to outputs.tf)

# Explanation: These outputs prove Chewbacca built private hyperspace lanes (endpoints) instead of public chaos.
# output "gru_vpce_ssm_id" {
#   value = aws_vpc_endpoint.gru_vpce_ssm01.id
# }

output "gru_vpce_logs_id" {
  value = aws_vpc_endpoint.gru_vpce_logs01.id
}

# output "gru_vpce_secrets_id" {
#   value = aws_vpc_endpoint.gru_vpce_secrets01.id
# }

output "gru_vpce_s3_id" {
  value = aws_vpc_endpoint.gru_vpce_s3_gw01.id
}

# output "gru_private_ec2_instance_id_bonus" {
#   value = aws_instance.gru_ec201_private_bonus.id
# }

# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
# output "gru_alb_dns_name" {
#   value = aws_lb.gru_alb01.dns_name
# }

# output "gru_app_fqdn" {
#   value = "${var.app_subdomain}.${var.domain_name}"
# }

output "gru_target_group_arn" {
  value = aws_lb_target_group.gru_tg01.arn
}

# output "gru_acm_cert_arn" {
#   value = aws_acm_certificate.gru_acm_cert01.arn
# }

# output "gru_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.gru_cf_waf01.arn : null
# }

# output "gru_dashboard_name" {
#   value = aws_cloudwatch_dashboard.gru.dashboard_name
# }

# output "gru_route53_zone_id" {
#   value = local.gru_zone_id
# }

# output "gru_app_url_https" {
#   value = "https://${var.app_subdomain}.${var.domain_name}"
# }

# output "gru_apex_url_https" {
#   value = "https://${var.domain_name}"
# }

output "gru_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.gru_alb_logs_bucket01[0].bucket : null
}

# output "gru_waf_log_destination" {
#   value = var.waf_log_destination
# }

# output "gru_waf_cw_log_group_name" {
#   value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.gru_waf_log_group01[0].name : null
# }

output "gru_tgw_id" {
  value = aws_ec2_transit_gateway.gru_tgw01.id
}