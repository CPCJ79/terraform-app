locals {
  tags = {
    AccountingCategory = "IT/Admin"
    Service            = "<service-tag>"
  }
}


module "ttam_app" {
  source = "../../../../modules/ttam_app"

  # Max 28 characters, aws limitation
  app_name = "<app_name>"

  # load_balancer_type
  # application -
  # https, ssl cert, 
  # network -
  # tcp, no cert, no policy

  load_balancer_type = "application"
  user_data          = file("${path.module}/user_data.sh")

  lb_port  = 443
  lb_proto = "HTTPS"

  app_port  = 8080
  app_proto = "HTTP"

  #postgres v 13 is supported for now, can easily add additional engines later
  db_instance = "postgres"
  db_name     = "<db_name>"
}

# Creates and store random password, to be stored in parameter store
# resource "random_password" "example_secret" {
#   length  = 16
#   special = false
# }

# resource "aws_ssm_parameter" "example_secret" {
#   name  = "/app/${var.app_name}/example_secret"
#   type  = "SecureString"
#   value = random_password.example_secret[0].result
# }


# Create and store a random username, to be stored in parameter store
# resource "random_string" "random_username" {
#   min_numeric = 0
#   length      = 8
#   special     = false
# }

# resource "aws_ssm_parameter" "random_username" {
#   name  = "/app/${var.app_name}/random_username"
#   type  = "String"
#   value = random_string.random_username[0].result
# }
