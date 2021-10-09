terraform {
  required_version = "~> 0.14"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/${var.vpc_name}/vpc/subnets/private/ids-list"
}

data "aws_ssm_parameter" "protected_subnets" {
  name = "/${var.vpc_name}/vpc/subnets/protected/ids-list"
}

resource "random_uuid" "efs_creation_token" {}

resource "aws_efs_file_system" "efs" {
  creation_token   = random_uuid.efs_creation_token.result
  performance_mode = "generalPurpose"
  encrypted        = "true"
}

resource "aws_efs_mount_target" "efs" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = (
    var.efs_subnet == "private" ?
    element(split(",", data.aws_ssm_parameter.private_subnets.value), 0) :
    element(split(",", data.aws_ssm_parameter.protected_subnets.value), 0)
  )
  security_groups = [var.instance_security_group]
  # Security Groups are not supported for network load balancer targets
}

resource "aws_efs_access_point" "efs-access-point" {
  file_system_id = aws_efs_file_system.efs.id
}
