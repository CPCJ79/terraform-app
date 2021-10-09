locals {
  tags = {
    AccountingCategory = "<Accounting Category>"
    Service            = "<Service>"
  }
}


module "ttam_app" {
  source = "../../../../modules/ttam_app"

  # Max 28 characters, aws limitation
  app_name = "<Application Name>"

  # load_balancer_type
  # application -
  # https, ssl cert, 

  load_balancer_type = "application"
  user_data          = file("${path.module}/user_data.sh")

  lb_port  = 443
  lb_proto = "HTTPS"

  app_port  = 443
  app_proto = "HTTP"

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
