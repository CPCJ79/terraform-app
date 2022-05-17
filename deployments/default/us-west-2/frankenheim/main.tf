terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.73.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

locals {
  tags = {
    AccountingCategory = "CaseyNSteve"
    Service            = "valheim"
  }
  app_name = "frankheim"
}


module "app" {
  source = "../../../../modules/app"

  app_name = local.app_name

  load_balancer_type = "network"
  user_data          = file("${path.module}/user_data.sh")

  lb_port = 19999
  lb_proto = "TCP"

  app_port  = 2456
  app_proto = "UDP"

  app0_port  = 2457
  app0_proto = "UDP"

  app1_port  = 2458
  app1_proto = "UDP"

  app2_port  = 19999
  app2_proto = "TCP"

  enable_efs = true

  # ASG 
  min_instance = 1
  max_instance = 1
}

resource "aws_ssm_parameter" "world_name" {
  name = "/app/${local.app_name}/world_name"
  type = "String"
  value = local.app_name
}

resource "aws_ssm_parameter" "world_password" {
  name = "/app/${local.app_name}/world_password"
  type = "SecureString"
  value = "butts"

}

resource "aws_autoscaling_schedule" "wakeup-weekday" {
  scheduled_action_name  = "wakeup"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "17 0 * * 1-5"
  autoscaling_group_name = module.app.asg_name
}

resource "aws_autoscaling_schedule" "wakeup-weekend" {
  scheduled_action_name  = "wakeup"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 0 * * 6-7"
  autoscaling_group_name = module.app.asg_name
}

resource "aws_autoscaling_schedule" "ssshhh" {
  scheduled_action_name  = "ssshhh"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "3 0 * * 6-7"
  autoscaling_group_name = module.app.asg_name
}
