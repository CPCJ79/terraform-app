####################################################
# APPLICATION LOAD BALANCER
####################################################

terraform {
  required_version = "~> 0.14"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

data "aws_ssm_parameter" "route53_zone_id" {
  name = "/${var.vpc_name}/route53/zone/id"
}
data "aws_ssm_parameter" "route53_zone_name" {
  name = "/${var.vpc_name}/route53/zone/name"
}

data "aws_acm_certificate" "cert" {
  domain   = "*.${data.aws_ssm_parameter.route53_zone_name.value}"
  statuses = ["ISSUED"]
}

# Application Load Balancer
resource "aws_lb" "instance" {
  name               = var.lb_name
  internal           = true
  load_balancer_type = var.load_balancer_type
  subnets            = var.lb_subnets
  # Security groups are not supported for load balancers with type 'network'
  security_groups            = var.load_balancer_type == "application" ? [aws_security_group.lb_sg_1[0].id, aws_security_group.lb_sg_2[0].id] : []
  idle_timeout               = 300
  drop_invalid_header_fields = true
}

# application alb listener
resource "aws_alb_listener" "listener" {
  count             = var.load_balancer_type == "application" ? 1 : 0
  load_balancer_arn = aws_lb.instance.arn
  port              = var.lb_port
  protocol          = var.lb_proto # tfsec:ignore:AWS004
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.instance.id
    type             = "forward"
  }
}

# network alb listener
resource "aws_alb_listener" "net_listener" {
  count             = var.load_balancer_type == "network" ? 1 : 0
  load_balancer_arn = aws_lb.instance.arn
  port              = var.lb_port
  protocol          = var.lb_proto # tfsec:ignore:AWS004

  default_action {
    target_group_arn = aws_lb_target_group.instance.id
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
    for_each = var.load_balancer_type == "application" ? [1] : []
    content {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = "10"
      port                = var.lb_app_port
      path                = var.health_path
      protocol            = var.lb_app_proto
      matcher             = var.health_response
    }
  }

  dynamic "health_check" {
    for_each = var.load_balancer_type == "network" ? [1] : []
    content {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      port                = var.lb_app_port
      protocol            = var.lb_app_proto
    }
  }
}

resource "aws_security_group" "lb_sg_1" {
  count       = var.load_balancer_type == "application" ? 1 : 0
  name        = join("-", [var.lb_name, "sg1"])
  description = var.lb_name
  vpc_id      = var.lb_sg_vpc_id

  ingress {
    description = "application_port ingress"
    from_port   = var.lb_app_port
    to_port     = var.lb_app_port
    protocol    = "TCP"
    cidr_blocks = var.lb_app_cidr
  }

  egress {
    description = "application_port egress"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.lb_app_cidr
  }
}

resource "aws_security_group" "lb_sg_2" {
  count       = var.load_balancer_type == "application" ? 1 : 0
  name        = join("-", [var.lb_name, "sg2"])
  description = var.lb_name
  vpc_id      = var.lb_sg_vpc_id

  ingress {
    description = "allow_lb_port"
    from_port   = var.lb_port
    to_port     = var.lb_port
    protocol    = "TCP"
    cidr_blocks = var.lb_app_cidr
  }

}

# for use case load balancer type none. 
resource "aws_security_group" "icmp" {
  count       = var.load_balancer_type == "none" ? 0 : 1
  name        = join("-", [var.lb_name, "sg-icmp"])
  description = var.lb_name
  vpc_id      = var.lb_sg_vpc_id

  ingress {
    description = "icmp echo"
    from_port   = "8"
    to_port     = "0"
    protocol    = "ICMP"
    cidr_blocks = var.lb_app_cidr
  }

}

resource "aws_route53_record" "instance_record" {
  zone_id = data.aws_ssm_parameter.route53_zone_id.value
  name    = join(".", [var.app_name, data.aws_ssm_parameter.route53_zone_name.value])
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.instance.dns_name]
}
