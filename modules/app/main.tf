terraform {
  required_version = "~> 0.14"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.vpc_name}/vpc/id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/${var.vpc_name}/vpc/subnets/private/ids-list"
}

data "aws_ssm_parameter" "protected_subnets" {
  name = "/${var.vpc_name}/vpc/subnets/protected/ids-list"
}

data "aws_ssm_parameter" "public_subnets" {
  name = "/${var.vpc_name}/vpc/subnets/public/ids-list"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "/${var.vpc_name}/vpc/cidr"
}

data "aws_ssm_parameter" "route53_zone_id" {
  name = "/${var.vpc_name}/route53/zone/id"
}

data "aws_ssm_parameter" "route53_zone_name" {
  name = "/${var.vpc_name}/route53/zone/name"
}

data "aws_ssm_parameter" "foundation2_ami_ecs" {
  name = "/app/latest-ami/foundation2-ami-ecs-hvm-x86_64-ebs/master"
}

data "aws_ssm_parameter" "foundation2_ami" {
  name = "/app/latest-ami/foundation2-ami-hvm-x86_64-ebs/master"
}

data "aws_default_tags" "default_tags" {}

resource "aws_iam_role" "test_role" {
  name = "test_role"

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

  tags = {
    "AccountingCategory" = data.aws_default_tags.default_tags.tags["AccountingCategory"]
    "Service"            = data.aws_default_tags.default_tags.tags["Service"]
  }
}

# tfsec:ignore:AWS099
resource "aws_iam_role_policy" "db_iam_access_policy" {
  count  = var.db_instance == "postgres" ? 1 : 0
  name   = join("-", [var.app_name, "db-pol"])
  role   = module.iam_role.role_name
  policy = data.aws_iam_policy_document.ssm-db-access-policy[0].json
}

module "alb" {
  source             = "../../modules/alb"
  count              = var.load_balancer_type == "none" ? 0 : 1
  load_balancer_type = var.load_balancer_type
  lb_name            = join("-", [var.app_name, "lb"])
  lb_app_port        = var.app_port
  lb_app_proto       = var.app_proto
  lb_subnets = (
    var.dep_subnet == "private" ?
    split(",", data.aws_ssm_parameter.private_subnets.value) :
    split(",", data.aws_ssm_parameter.protected_subnets.value)
  )
  # Security Groups are not supported for network load balancer targets
  lb_tg_name      = join("-", [var.app_name, "tg"])
  lb_tg_vpc_id    = data.aws_ssm_parameter.vpc_id.value
  lb_proto        = var.lb_proto
  lb_port         = var.lb_port
  lb_sg_vpc_id    = data.aws_ssm_parameter.vpc_id.value
  lb_app_cidr     = var.app_cidr
  health_path     = var.health_path
  health_response = var.health_response
  app_name        = var.app_name
}

module "efs" {
  source                  = "../../modules/efs"
  count                   = var.enable_efs ? 1 : 0
  instance_security_group = aws_security_group.allow_app_port.id
  efs_subnet              = var.dep_subnet
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

data "aws_iam_policy_document" "ssm-db-access-policy" {
  count = var.db_instance == "postgres" ? 1 : 0
  statement {
    sid = "SMDBAccess"

    actions = [
      "rds-db:connect"
    ]

    resources = [
      aws_db_instance.instance[0].arn
    ]
  }
}

resource "aws_iam_instance_profile" "instance_instprof" {
  name = join("-", [var.app_name, "prof"])
  role = module.iam_role.role_name
}

resource "aws_security_group" "sg_egress" {
  name        = join("-", [var.app_name, "sg-egress"])
  description = var.app_name
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

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
  image_id             = data.aws_ssm_parameter.foundation2_ami.value
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.sg_egress.id, aws_security_group.allow_lb_port.id, aws_security_group.allow_app_port.id]
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
  vpc_zone_identifier = (
    var.dep_subnet == "private" ?
    split(",", data.aws_ssm_parameter.private_subnets.value) :
    split(",", data.aws_ssm_parameter.protected_subnets.value)
  )
  target_group_arns         = var.load_balancer_type == "none" ? [] : [module.alb[0].tg_arn]
  health_check_type         = var.load_balancer_type == "none" ? null : "ELB"
  health_check_grace_period = var.load_balancer_type == "none" ? null : "300"
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

resource "aws_security_group" "allow_lb_port" {
  # count       = (can(coalesce(var.lb_port))) ? 1 : 0
  name        = join("-", [var.app_name, "lb-port"])
  description = var.app_name
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # if lb_port is set, create ingress rule. If lb_port is not set no ingress rule. 
  dynamic "ingress" {
    for_each = (can(coalesce(var.lb_port))) ? [1] : []
    content {
      description = "allow_lb_port"
      from_port   = var.lb_port
      to_port     = var.lb_port
      protocol    = "TCP"
      cidr_blocks = [data.aws_ssm_parameter.vpc_cidr.value]
    }
  }

}

resource "aws_security_group" "allow_app_port" {
  # count       = (can(coalesce(var.app_port))) ? 1 : 0
  name        = join("-", [var.app_name, "app-port"])
  description = var.app_name
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

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

resource "random_string" "db_username" {
  count       = var.db_instance == "postgres" ? 1 : 0
  min_numeric = 0
  length      = 8
  special     = false
}

resource "aws_ssm_parameter" "db_username" {
  count = var.db_instance == "postgres" ? 1 : 0
  name  = "/app/${var.app_name}/db_username"
  type  = "String"
  value = random_string.db_username[0].result
}

resource "random_password" "db_password" {
  count   = var.db_instance == "postgres" ? 1 : 0
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  count = var.db_instance == "postgres" ? 1 : 0
  name  = "/app/${var.app_name}/db_password"
  type  = "SecureString"
  value = random_password.db_password[0].result
}

#RDS DB
# tfsec:ignore:AWS091
resource "aws_db_instance" "instance" {
  count                               = var.db_instance == "postgres" ? 1 : 0
  allocated_storage                   = 10
  engine_version                      = "13"
  engine                              = "postgres"
  instance_class                      = "db.t3.medium"
  name                                = var.db_name
  username                            = aws_ssm_parameter.db_username[0].value
  password                            = aws_ssm_parameter.db_password[0].value
  storage_encrypted                   = true
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  deletion_protection                 = true
  db_subnet_group_name                = aws_db_subnet_group.instance[0].id
  vpc_security_group_ids              = [aws_security_group.db_sg[0].id]
  skip_final_snapshot                 = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
}

resource "aws_db_subnet_group" "instance" {
  name = var.app_name
  subnet_ids = (
    var.dep_subnet == "private" ?
    split(",", data.aws_ssm_parameter.private_subnets.value) :
    split(",", data.aws_ssm_parameter.protected_subnets.value)
  )
  count = var.db_instance == "postgres" ? 1 : 0
}

# tfsec:ignore:AWS018
resource "aws_security_group" "db_sg" {
  count  = var.db_instance == "postgres" ? 1 : 0
  name   = join("-", [var.app_name, "db-sg"])
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
