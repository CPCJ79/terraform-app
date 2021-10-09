remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "ttam-cloud-infra-tf-state-us-west-2"
    key            = "${get_env("DRONE_REPO_NAME")}/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}

locals {
  # Determine our account name based on repo path "deployments/<account_name>/<region>/<deployment>" in context.
  aws_account_name = element(split("/", "${path_relative_to_include()}"), 1)
  aws_account_id   = run_cmd("--terragrunt-quiet", "/usr/local/utils/get-account-id", local.aws_account_name)
  aws_region       = element(split("/", "${path_relative_to_include()}"), 2)
  deployment_name  = element(split("/", "${path_relative_to_include()}"), 3)
}

inputs = {
  deployment_name = local.deployment_name
}

generate "default_tags" {
  path = "default-tags.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    locals {
      default_tags = {
        "Repo"                    = "${get_env("DRONE_REPO_NAME")}"
        "terraform:workspace"     = terraform.workspace
        "terraform:state:backend" = "s3"
        "terraform:state:key"     = "s3://ttam-cloud-infra-tf-state-us-west-2/${get_env("DRONE_REPO_NAME")}/${path_relative_to_include()}/terraform.tfstate"
      }

      merged_tags = merge(local.default_tags, local.tags)
    }
  EOF
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    # local.aws_account_name: ${local.aws_account_name}
    # local.aws_account_id: ${local.aws_account_id}
    # local.aws_region: ${local.aws_region}
    # local.deployment_name: ${local.deployment_name}

    terraform {
      required_version = "~> 0.14.0"

      required_providers {
        aws = {
          version = "~> 3.38"
        }
      }
    }

    provider "aws" {
      region = "${local.aws_region}"

      assume_role {
        role_arn = "arn:aws:iam::${local.aws_account_id}:role/OrganizationAccountAccessRole"
      }

      default_tags {
        tags = local.merged_tags
      }
    }
  EOF
}

terraform {
  extra_arguments "output" {
    commands  = ["plan"]
    arguments = ["-out", "terraform.plan"]
  }

  after_hook "json_plan" {
    commands = ["plan"]
    execute  = [
      "/usr/local/bin/build-json-plan",
    ]
  }
}
