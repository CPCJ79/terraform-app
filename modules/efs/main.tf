terraform {
  required_version = "~> 1.0"
}

resource "random_uuid" "efs_creation_token" {}

resource "aws_efs_file_system" "efs" {
  creation_token   = random_uuid.efs_creation_token.result
  performance_mode = "generalPurpose"
  encrypted        = "true"
}

resource "aws_efs_mount_target" "efs" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = ("subnet-09c78817d0d8cb4a7")
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
