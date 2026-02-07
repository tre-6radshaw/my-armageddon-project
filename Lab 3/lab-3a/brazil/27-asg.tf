resource "aws_autoscaling_group" "gru_asg" {
  name_prefix               = "${var.project_name}-asg-"
  min_size                  = 3
  max_size                  = 9
  desired_capacity          = 6
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  vpc_zone_identifier = aws_subnet.gru_private_subnets[*].id

  target_group_arns = [aws_lb_target_group.gru_tg01.arn]

  launch_template {
    id      = aws_launch_template.gru_TB.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  # Optional: protect new instances briefly during launch
  initial_lifecycle_hook {
    name                 = "instance-protection-launch"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }

  # Optional: give instances time to deregister cleanly
  initial_lifecycle_hook {
    name                 = "scale-in-protection"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity] # let autoscaling manage desired capacity
  }
}


# Target Tracking Policy (CPU-based scaling) — very common & recommended
resource "aws_autoscaling_policy" "gru_cpu_target_policy" {
  name                      = "${var.project_name}-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.gru_asg.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # adjust to your preference (60–75% common)
  }
}


# The attachment is usually not needed when you already specify target_group_arns in the ASG
# You can safely remove this block unless you have special requirements:
# resource "aws_autoscaling_attachment" "gru_asg_attachment" { ... }
# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "web-tier-attachment" {
  autoscaling_group_name = aws_autoscaling_group.gru_asg.name
  lb_target_group_arn    = aws_lb_target_group.gru_tg01.arn
}