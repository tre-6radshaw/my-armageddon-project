############################################
# ACM Certificate (TLS) for Cloudfront (US-EAST-1)
############################################

# # Explanation: TLS is the diplomatic passport — browsers trust you, and Chewbacca stops growling at plaintext.
# resource "aws_acm_certificate" "cf_acm_cert01" {
#   provider                  = aws.useast1
#   domain_name               = local.edo_fqdn
#   subject_alternative_names = [var.domain_name]
#   validation_method         = var.certificate_validation_method

#   # TODO: students can add subject_alternative_names like var.domain_name if desired

#   tags = {
#     Name = "${var.project_name}-cf-acm-cert01"
#   }
# }

# # Explanation: DNS validation records are the “prove you own the planet” ritual — Route53 makes this elegant.
# # TODO: students implement aws_route53_record(s) if they manage DNS in Route53.
# # resource "aws_route53_record" "chewbacca_acm_validation" { ... }

# # Explanation: Once validated, ACM becomes the “green checkmark” — until then, ALB HTTPS won’t work.
# resource "aws_acm_certificate_validation" "cf_acm_validation01" {
#   provider = aws.useast1
#   certificate_arn = aws_acm_certificate.cf_acm_cert01.arn

#   # # TODO: if using DNS validation, students must pass validation_record_fqdns
#   # validation_record_fqdns = [aws_route53_record.edo_acm_validation_records01.fqdn]

#   #adding from the template resource below as test
#   validation_record_fqdns = [
#     for r in aws_route53_record.edo_acm_validation_records01 : r.fqdn
#   ]

#   timeouts {
#     create = "30m" # optional: give more time if propagation is slow
#   }
# }

# Explanation: TLS is the diplomatic passport — browsers trust you, and Chewbacca stops growling at plaintext.
resource "aws_acm_certificate" "edo_acm_cert01" {
  domain_name               = local.edo_fqdn
  subject_alternative_names = [var.domain_name]
  validation_method         = var.certificate_validation_method

  # TODO: students can add subject_alternative_names like var.domain_name if desired

  tags = {
    Name = "${var.project_name}-acm-cert01"
  }
}

# Explanation: DNS validation records are the “prove you own the planet” ritual — Route53 makes this elegant.
# TODO: students implement aws_route53_record(s) if they manage DNS in Route53.
# resource "aws_route53_record" "chewbacca_acm_validation" { ... }

# Explanation: Once validated, ACM becomes the “green checkmark” — until then, ALB HTTPS won’t work.
resource "aws_acm_certificate_validation" "edo_acm_validation01" {
  certificate_arn = aws_acm_certificate.edo_acm_cert01.arn

  # # TODO: if using DNS validation, students must pass validation_record_fqdns
  # validation_record_fqdns = [aws_route53_record.edo_acm_validation_records01.fqdn]

  #adding from the template resource below as test
  validation_record_fqdns = [
    for r in aws_route53_record.edo_acm_validation_records01 : r.fqdn
  ]

  timeouts {
    create = "30m" # optional: give more time if propagation is slow
  }
}

############################################
# ACM DNS Validation Records
############################################

# Explanation: ACM asks “prove you own this planet”—DNS validation is Chewbacca roaring in the right place.
resource "aws_route53_record" "edo_acm_validation_records01" {
  allow_overwrite = true
  for_each = var.certificate_validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.edo_acm_cert01.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = local.edo_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}