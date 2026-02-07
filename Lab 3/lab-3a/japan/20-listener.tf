############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
############################################

# Explanation: HTTP listener is the decoy airlock — it redirects everyone to the secure entrance.
resource "aws_lb_listener" "edo_http_listener01" {
  load_balancer_arn = aws_lb.edo_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Explanation: HTTPS listener is the real hangar bay — TLS terminates here, then traffic goes to private targets.
resource "aws_lb_listener" "edo_https_listener01" {
  load_balancer_arn = aws_lb.edo_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.edo_acm_validation01.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.edo_tg01.arn
  }

  depends_on = [aws_acm_certificate_validation.edo_acm_validation01]
}

### Lab 2a
# Explanation: This is Chewbacca’s secret handshake — if the header isn’t present, you don’t get in.
resource "random_password" "edo_origin_header_value01" {
  length  = 32
  special = false
}

# Explanation: ALB checks for Chewbacca’s secret growl — no growl, no service.
resource "aws_lb_listener_rule" "edo_require_origin_header01" {
  listener_arn = aws_lb_listener.edo_https_listener01.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.edo_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-edo-Growl"
      values           = [random_password.edo_origin_header_value01.result]
    }
  }
}

# Explanation: If you don’t know the growl, you get a 403 — Chewbacca does not negotiate.
resource "aws_lb_listener_rule" "edo_default_block01" {
  listener_arn = aws_lb_listener.edo_https_listener01.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern { values = ["*"] }
  }
}