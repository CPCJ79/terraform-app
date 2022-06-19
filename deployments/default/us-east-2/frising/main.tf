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
    Service            = "frising"
  }
  app_name = "frising"
}


module "app" {
  source = "../../../../modules/app"

  app_name = local.app_name

  load_balancer_type = "network"
  user_data          = file("${path.module}/user_data.sh")

  lb_port = 27015
  lb_proto = "TCP"

  app_port  = 27016
  app_proto = "UDP"

  app0_port  = 9876
  app0_proto = "UDP"

  app1_port  = 9877
  app1_proto = "UDP"

  app2_port  = 9878
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
