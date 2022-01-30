terraform {
  backend "s3" {
    bucket = "cpcj79-us-west-2-terraform-state"
    key    = "game-server/valheim/frankheim/terraform.tfstate"
    region = "us-west-2"
  }
}
