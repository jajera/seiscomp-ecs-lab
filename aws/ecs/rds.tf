resource "random_password" "db" {
  length  = 20
  special = false
}

resource "random_password" "rdp" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db" {
  name  = local.ssm_db
  type  = "SecureString"
  value = random_password.db.result
}

resource "aws_ssm_parameter" "rdp" {
  name  = local.ssm_rdp
  type  = "SecureString"
  value = random_password.rdp.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = local.name
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_db_parameter_group" "this" {
  name   = "${local.name}-mariadb114"
  family = "mariadb11.4"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_bin"
  }

  parameter {
    name  = "require_secure_transport"
    value = "0"
  }
}

resource "aws_db_instance" "this" {
  identifier                   = local.name
  engine                       = "mariadb"
  engine_version               = "11.4"
  instance_class               = "db.t3.micro"
  allocated_storage            = 20
  storage_type                 = "gp3"
  db_name                      = "seiscomp"
  username                     = "sysop"
  password                     = random_password.db.result
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.rds.id]
  parameter_group_name         = aws_db_parameter_group.this.name
  publicly_accessible          = false
  storage_encrypted            = true
  multi_az                     = false
  skip_final_snapshot          = true
  deletion_protection          = false
  backup_retention_period      = 1
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  performance_insights_enabled = false
}
