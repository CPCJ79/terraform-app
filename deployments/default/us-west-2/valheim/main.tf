locals {
  tags = {
    AccountingCategory = "CaseyNSteve"
    Service            = "valheim"
  }
  app_name = "Frankheim"
}


module "app" {
  source = "../../../../modules/app"

  app_name = local.app_name

  load_balancer_type = "network"
  user_data          = file("${path.module}/user_data.sh")

  app_port  = 2456
  app_proto = "TCP"

  enable_efs = true

  # ASG 
  min_instance = 1
  max_instance = 1
}

# network alb listener
resource "aws_alb_listener" "net_listener0" {
  load_balancer_arn = module.app.alb.id

  port              = 2457
  protocol          = "TCP"

  default_action {
    target_group_arn = module.app.alb.tg_arn
    type             = "forward"
  }
}

resource "aws_ssm_parameter" "world_name" {
  name = "world_name"
  type = "String"
  value = local.app_name
}

resource "random_password" "world_password" {
  length           = 8
  special          = false
}

resource "aws_ssm_parameter" "world_password" {
  name = "/app/${local.app_name}/world_password"
  type = "String"
  value = random_password.world_password
}
