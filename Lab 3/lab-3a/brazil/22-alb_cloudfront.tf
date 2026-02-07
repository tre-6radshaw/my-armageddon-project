# Explanation: CloudFront is the only public doorway — Chewbacca stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "gru_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.gru_alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-gru-Growl"
      value = random_password.gru_origin_header_value01.result
    }
  }

  # default_cache_behavior {
  #   target_origin_id       = "${var.project_name}-alb-origin01"
  #   viewer_protocol_policy = "redirect-to-https"

  #   allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  #   cached_methods  = ["GET", "HEAD"]

  #   # TODO: students choose cache policy / origin request policy for their app type
  #   # For APIs, typically forward all headers/cookies/querystrings.
  #   forwarded_values {
  #     query_string = true
  #     headers      = ["*"]
  #     cookies { forward = "all" }
  #   }
  # }

  # ── NEW: Add these for Lab 2B-Honors ────────────────────────────────────────
  # Higher precedence (evaluated first): Specific public-feed with origin-driven caching
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.gru_use_origin_cache_headers01.id

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.gru_orp_all_viewer_except_host01.id
  }

  # Lower precedence: General /api/* with caching disabled
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.gru_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.gru_orp_api01.id
  }

  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.gru_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.gru_orp_api01.id
  }

  # Explanation: Static behavior is the speed lane—Chewbacca caches it hard for performance.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.gru_cache_static01.id
    # origin_request_policy_id = aws_cloudfront_origin_request_policy.gru_orp_static01.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.gru_orp_all_viewer01.id # ← Now forwards Host header
    response_headers_policy_id = aws_cloudfront_response_headers_policy.gru_rsp_static01.id
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.gru_cf_waf01.arn

  # TODO: students set aliases for chewbacca-growl.com and app.chewbacca-growl.com
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # TODO: students must use ACM cert in us-east-1 for CloudFront
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cf_acm_cert01.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
