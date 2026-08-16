resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "Fargate tasks and GUI"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SeisComP mesh"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Keep aws_security_group_rule.app_from_alb; replacing this SG's ingress
  # list would delete that ALB rule and FDSNWS health checks time out.
  lifecycle {
    ignore_changes = [ingress]
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "MariaDB from app only"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "NFS from app"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group" "vpce" {
  name        = "${local.name}-vpce"
  description = "HTTPS to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-fdsnws-alb"
  description = "Internal FDSNWS ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Windows mstsc (no AWS CLI). Do not put 3389 on the Fargate app SG.
resource "aws_security_group" "gui_rdp" {
  count       = var.deploy_services ? 1 : 0
  name        = "${local.name}-gui-rdp"
  description = "RDP from operator /32"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "xrdp"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.operator_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Not inline on app: app and alb would cycle if they both referenced each other.
resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "FDSNWS from internal ALB"
}
