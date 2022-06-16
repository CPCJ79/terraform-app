terraform {
  required_version = "~> 1.0"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "tag:network_hack_name"
    values = ["games_net"]
  }
}

resource "random_uuid" "efs_creation_token" {}

resource "aws_efs_file_system" "efs" {
  creation_token   = random_uuid.efs_creation_token.result
  performance_mode = "generalPurpose"
  encrypted        = "true"
}

resource "aws_efs_mount_target" "efs" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = (data.aws_subnet.default.id)
  security_groups = [var.instance_security_group]
  # Security Groups are not supported for network load balancer targets
}

resource "aws_efs_access_point" "efs-access-point" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/valheim"
    creation_info {
      owner_gid = 0
      owner_uid = 0
      permissions = "755"
    }
  }
}

resource "aws_ssm_parameter" "efs_access_point" {
  name = "/app/${var.app_name}/efs_access_point"
  type = "String"
  value = aws_efs_access_point.efs-access-point.id
}

resource "aws_ssm_parameter" "efs_fs_id" {
  name = "/app/${var.app_name}/efs_fs_id"
  type = "String"
  value = aws_efs_access_point.efs-access-point.file_system_id
}