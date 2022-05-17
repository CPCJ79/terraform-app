terraform {
  required_version = "~> 1.0"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_default_tags" "default_tags" {}

resource "aws_iam_role" "instance_role" {
  name = "${var.app_name}-Role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

module "alb" {
  source             = "../../modules/alb"
  count              = var.load_balancer_type == "none" ? 0 : 1
  load_balancer_type = "network"
  lb_name            = join("-", [var.app_name, "lb"])
  lb_app_port        = var.app_port
  lb_app_proto       = var.app_proto
  lb_app0_port        = var.app0_port
  lb_app0_proto       = var.app0_proto
  lb_app1_port        = var.app1_port
  lb_app1_proto       = var.app1_proto
  lb_app2_port        = var.app2_port
  lb_app2_proto       = var.app2_proto
  lb_subnets = ["subnet-09c78817d0d8cb4a7"]
  # Security Groups are not supported for network load balancer targets
  lb_tg_name      = join("-", [var.app_name, "tg"])
  lb_tg_vpc_id    = "vpc-017932fd879703868"
  lb_proto        = var.lb_proto
  lb_port         = var.lb_port
  lb_sg_vpc_id    = "vpc-017932fd879703868"
  lb_app_cidr     = var.app_cidr
  health_path     = var.health_path
  health_response = var.health_response
  app_name        = var.app_name
}

module "efs" {
  source                  = "../../modules/efs"
  count                   = var.enable_efs ? 1 : 0
  instance_security_group = aws_security_group.allow_app_port.id
  efs_subnet              = "subnet-09c78817d0d8cb4a7"
}

data "aws_iam_policy_document" "instance_iam_policy" {
  statement {
    sid = "SSMPolicy"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/app/${var.app_name}/*",
    ]
  }

  statement {
    sid = "SSMManager"

    actions = [
      "ssm:UpdateInstanceInformation",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "s3:GetEncryptionConfiguration",
    ]

    resources = ["*"]
  }
}

# tfsec:ignore:AWS099
resource "aws_iam_role_policy" "iam_access_policy" {
  name   = join("-", [var.app_name, "-pol"])
  role   = aws_iam_role.instance_role.name
  policy = data.aws_iam_policy_document.instance_iam_policy.json
}

resource "aws_iam_instance_profile" "instance_instprof" {
  name = join("-", [var.app_name, "prof"])
  role = aws_iam_role.instance_role.name
}

resource "aws_security_group" "sg_egress" {
  name        = join("-", [var.app_name, "sg-egress"])
  description = var.app_name
  vpc_id      = "vpc-017932fd879703868"

  # if app port is set, create egress rule. If app port is not set no egress rule. 
  dynamic "egress" {
    for_each = (can(coalesce(var.app_port))) ? [1] : []
    content {
      description = "security group egress"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"] # tfsec:ignore:AWS009
    }
  }
}

# tfsec:ignore:AWS014
resource "aws_launch_configuration" "instance_lc" {
  name_prefix          = join("-", [var.app_name, "lc"])
  image_id             = "ami-06cffe063efe892ad"
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.sg_egress.id, aws_security_group.allow_app_port.id]
  iam_instance_profile = aws_iam_instance_profile.instance_instprof.name
  user_data            = var.user_data

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

}

resource "aws_autoscaling_group" "instance_asg" {
  name                 = join("-", [var.app_name, "asg"])
  launch_configuration = aws_launch_configuration.instance_lc.name
  min_size             = var.min_instance
  max_size             = var.max_instance
  vpc_zone_identifier = ["subnet-09c78817d0d8cb4a7"]
  target_group_arns         = [module.alb[0].tg_arn, module.alb[0].tg0_arn, module.alb[0].tg1_arn, module.alb[0].tg2_arn]
  health_check_type         = "ELB"
  health_check_grace_period = "300"
  max_instance_lifetime     = 604800 # 1 week

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = data.aws_default_tags.default_tags.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = var.app_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "allow_app_port" {
  # count       = (can(coalesce(var.app_port))) ? 1 : 0
  name        = join("-", [var.app_name, "app-port"])
  description = var.app_name
  vpc_id      = "vpc-017932fd879703868"

  # if lb_port is set, create ingress rule. If lb_port is not set no ingress rule. 
  dynamic "ingress" {
    for_each = (can(coalesce(var.app_port))) ? [1] : []
    content {
      description = "allow_app_port"
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "TCP"
      cidr_blocks = var.app_cidr
    }
  }
}

resource "aws_security_group_rule" "instance0" {
  type              = "ingress"
  from_port         = var.app0_port
  to_port           = var.app0_port
  protocol          = var.app0_proto
  cidr_blocks       = var.app_cidr
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instance1" {
  type              = "ingress"
  from_port         = var.app1_port
  to_port           = var.app1_port
  protocol          = var.app1_proto
  cidr_blocks       = var.app_cidr
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instance2" {
  type              = "ingress"
  from_port         = var.app2_port
  to_port           = var.app2_port
  protocol          = var.app2_proto
  cidr_blocks       = var.app_cidr
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instanceTCP" {
  type              = "ingress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "TCP"
  cidr_blocks       = var.app_cidr
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instanceUDP" {
  type              = "ingress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "UDP"
  cidr_blocks       = var.app_cidr
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instancePUBTCP" {
  type              = "ingress"
  from_port         = "19999"
  to_port           = "19999"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_app_port.id
}

resource "aws_security_group_rule" "instancePUBUDP" {
  type              = "ingress"
  from_port         = "2456"
  to_port           = "2458"
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_app_port.id
}
