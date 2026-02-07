############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "edo_log_group01" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "edo_db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "edo/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.edo_sns_topic01.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

# Explanation: When the ALB starts throwing 5xx, that’s the Falcon coughing — page the on-call Wookiee.
resource "aws_cloudwatch_metric_alarm" "edo_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.edo_alb01.arn_suffix
  }

  alarm_actions = [aws_sns_topic.edo_sns_topic01.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard (Skeleton)
############################################

# Explanation: Dashboards are your cockpit HUD — Chewbacca wants dials, not vibes.
resource "aws_cloudwatch_dashboard" "edo_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  # TODO: students can expand widgets; this is a minimal workable skeleton
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.edo_alb01.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.edo_alb01.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "edo ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.edo_alb01.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "edo ALB: Target Response Time"
        }
      }
    ]
  })
}