############################################
# Locals (naming convention: gru-*) (Brotherhood Of Steel)
############################################
locals {
  name_prefix = var.project_name
}

############################################
# Bonus A - Data + Locals
############################################

# Explanation: gru wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "gru_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "gru_region01" {}

locals {
  # Explanation: Name prefix is the roar that echoes through every tag.
  gru_prefix = var.project_name

  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  gru_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.gru_region01.region}:${data.aws_caller_identity.gru_self01.account_id}:secret:${local.gru_prefix}/rds/mysql*"
}

############################################
# Bonus B - ALB (Public) -> Target Group (Private EC2) + TLS + WAF + Monitoring
############################################

locals {
  # Explanation: This is the roar address — where the galaxy finds your app.
  gru_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Bonus B - Route53 (Hosgted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

locals {
  # Explanation: Chewbacca needs a home planet—Route53 hosted zone is your DNS territory.
  gru_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (students choose their destiny).
  # gru_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.gru_zone01[0].zone_id : var.route53_hosted_zone_id
  gru_zone_id = var.route53_hosted_zone_id
  # Explanation: This is the app address that will growl at the galaxy (app.chewbacca-growl.com).
  gru_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

### Data
### Lab 2B
# Explanation: Chewbacca only opens the hangar to CloudFront — everyone else gets the Wookiee roar.
data "aws_ec2_managed_prefix_list" "gru_cf_origin_facing01" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_cloudfront_origin_request_policy" "gru_orp_all_viewer01" {
  name = "Managed-AllViewer"
}

# Managed AWS policy that disables caching entirely (TTL=0 everywhere, none for cookies/queries/headers)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "managed_all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader" # Forwards viewer Host, cookies, queries, etc.
}

data "aws_cloudfront_origin_request_policy" "gru_orp_all_viewer_except_host01" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "gru_use_origin_cache_headers01" {
  name = "UseOriginCacheControlHeaders"
}

# Explanation: Same idea, but includes query strings in the cache key when your API truly varies by them.
data "aws_cloudfront_cache_policy" "gru_use_origin_cache_headers_qs01" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# Data source to get the official CloudFront log delivery canonical ID (future-proof)
data "aws_cloudfront_log_delivery_canonical_user_id" "current" {}

data "aws_canonical_user_id" "current" {}

# Explanation: This is the AMI for the EC2 app host—Amazon Linux 2023 with latest patches (as of June 2024).
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
      name   = "name"
      values = ["al2023-ami-2023*-x86_64"]
    }
  }