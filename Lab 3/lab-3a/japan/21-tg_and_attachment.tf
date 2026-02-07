############################################
# Target Group + Attachment
############################################

# Explanation: Target groups are Chewbacca’s “who do I forward to?” list — private EC2 lives here.
resource "aws_lb_target_group" "edo_tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.edo_vpc01.id

  # TODO: students set health check path to something real (e.g., /health)
  health_check {
    enabled             = true
    interval            = 30
    path                = "/" ### not really sure about this
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg01"
  }
}

# # Explanation: Chewbacca personally introduces the ALB to the private EC2 — “this is my friend, don’t shoot.”
# resource "aws_lb_target_group_attachment" "edo_tg_attach01" {
#   target_group_arn = aws_lb_target_group.edo_tg01.arn
#   target_id        = aws_instance.edo_ec201_private_bonus.id
#   port             = 80

#   # TODO: students ensure EC2 security group allows inbound from ALB SG on this port (rule above)
# }