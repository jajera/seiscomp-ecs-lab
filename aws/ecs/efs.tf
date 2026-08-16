resource "aws_efs_file_system" "sds" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  tags             = { Name = "${local.name}-sds" }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "sds" {
  count           = 2
  file_system_id  = aws_efs_file_system.sds.id
  subnet_id       = aws_subnet.app[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "sds" {
  file_system_id = aws_efs_file_system.sds.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/sds"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }
}
