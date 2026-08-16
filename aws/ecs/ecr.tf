resource "aws_ecr_repository" "base" {
  name                 = "${var.project}-base"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "gui" {
  name                 = "${var.project}-gui"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_service_discovery_private_dns_namespace" "scnet" {
  name = local.namespace
  vpc  = aws_vpc.this.id
}

resource "aws_service_discovery_service" "scmaster" {
  name = "scmaster"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.scnet.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "seedlink" {
  name = "seedlink"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.scnet.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name}"
  retention_in_days = 7
}
