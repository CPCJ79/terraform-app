####################################################
# APPLICATION LOAD BALANCER
####################################################

terraform {
  required_version = "~> 1.0"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

# Application Load Balancer
resource "aws_lb" "instance" {
  name               = var.lb_name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.lb_subnets
  # Security groups are not supported for load balancers with type 'network'
  idle_timeout               = 300
  drop_invalid_header_fields = true
}

# network alb listener
resource "aws_alb_listener" "net_listener" {
  load_balancer_arn = aws_lb.instance.arn

  port              = var.app_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.instance.id
    type             = "forward"
  }
}

