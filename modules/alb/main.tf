####################################################
# APPLICATION LOAD BALANCER
####################################################

terraform {
  required_version = "~> 1.0"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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

  port              = var.lb_app_port
  protocol          = var.lb_app_proto

  default_action {
    target_group_arn = aws_lb_target_group.instance.id
    type             = "forward"
  }
}

# network alb listener
resource "aws_alb_listener" "net_listener0" {
  load_balancer_arn = aws_lb.instance.arn

  port              = var.lb_app2_port
  protocol          = var.lb_app2_proto

  default_action {
    target_group_arn = aws_lb_target_group.instance0.id
    type             = "forward"
  }
}

# Application or network traget group dynamic block
resource "aws_lb_target_group" "instance" {
  name     = var.lb_tg_name
  port     = var.lb_app_port
  protocol = var.lb_app_proto
  vpc_id   = var.lb_tg_vpc_id

  dynamic "health_check" {
    for_each = var.load_balancer_type == "network" ? [1] : []
    content {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      port                = var.lb_app_port
      protocol            = "TCP"
    }
  }
}

# Application or network traget group dynamic block
resource "aws_lb_target_group" "instance0" {
  name     = "${var.lb_tg_name}0"
  port     = var.lb_app2_port
  protocol = var.lb_app2_proto
  vpc_id   = var.lb_tg_vpc_id

  dynamic "health_check" {
    for_each = var.load_balancer_type == "network" ? [1] : []
    content {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      port                = var.lb_app2_port
      protocol            = "TCP"
    }
  }
}
