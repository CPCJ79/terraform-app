terraform {
  backend "s3" {
    bucket = "guihack-us-west-2-terraform-state"
    key    = "game-server/valheim/guihack-valheim/terraform.tfstate"
    region = "us-east-2"
  }
}
