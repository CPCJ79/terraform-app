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
  app_name = "Frankheim"
}


module "app" {
  source = "../../../../modules/app"

  app_name = local.app_name

  load_balancer_type = "network"
  user_data          = file("${path.module}/user_data.sh")

  app_port  = 2456
  app_proto = "TCP"

  app2_port = 2457
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

resource "random_password" "world_password" {
  min_numeric      = 0
  length           = 8
  special          = false
}

resource "aws_ssm_parameter" "world_password" {
  name = "/app/${local.app_name}/world_password"
  type = "SecureString"
  value = random_password.world_password.result
}
