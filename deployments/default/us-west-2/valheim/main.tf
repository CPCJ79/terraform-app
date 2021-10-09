locals {
  tags = {
    AccountingCategory = "Gaymes"
    Service            = "valheim"
  }
}


module "ttam_app" {
  source = "../../../../modules/ttam_app"

  # Max 28 characters, aws limitation
  app_name = "valheim"

  # load_balancer_type
  # application -
  # https, ssl cert, 
  # network -
  # tcp, no cert, no policy


  load_balancer_type = "none"
  user_data          = file("${path.module}/user_data.sh")

  dep_subnet = "protected"

  app_port  = 2456
  app_proto = "TCP"

  enable_efs = true

  # ASG 
  min_instance = 1
  max_instance = 1
}
