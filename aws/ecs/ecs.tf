resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

locals {
  common_env = [
    { name = "DB_HOST", value = aws_db_instance.this.address },
    { name = "DB_USER", value = "sysop" },
    { name = "DB_NAME", value = "seiscomp" },
    { name = "SEEDLINK_HOST", value = local.seedlink_dns },
    { name = "SCMASTER_HOST", value = local.scmaster_dns },
  ]

  db_secret = [
    {
      name      = "DB_PASSWORD"
      valueFrom = aws_ssm_parameter.db.arn
    }
  ]

  log_cfg = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.ecs.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "ecs"
    }
  }

  stations_env = concat(local.common_env, [
    { name = "WAIT_FOR_STATIONS", value = "1" }
  ])

  station_feed = [
    { name = "SEEDLINK_UPSTREAM_HOST", value = var.seedlink_upstream_host },
    { name = "SEEDLINK_UPSTREAM_PORT", value = tostring(var.seedlink_upstream_port) },
    { name = "SEEDLINK_NETWORK", value = var.seedlink_network },
    { name = "SEEDLINK_STATIONS", value = var.seedlink_stations },
    { name = "SEEDLINK_SELECTORS", value = var.seedlink_selectors },
    { name = "INVENTORY_FDSN_BASE", value = var.inventory_fdsn_base },
    { name = "INVENTORY_FDSN_LEVEL", value = var.inventory_fdsn_level },
    { name = "INVENTORY_MIN_STATIONS", value = tostring(var.inventory_min_stations) },
  ]

  # Listeners: TCP to the process port. Others: process still running.
  health_tcp = {
    interval    = 30
    timeout     = 5
    retries     = 5
    startPeriod = 240
  }
  health_scmaster = merge(local.health_tcp, {
    command = ["CMD-SHELL", "python3 -c 'import socket; socket.create_connection((\"127.0.0.1\",18180),2).close()'"]
  })
  health_seedlink = merge(local.health_tcp, {
    command = ["CMD-SHELL", "python3 -c 'import socket; socket.create_connection((\"127.0.0.1\",18000),2).close()'"]
  })
  health_fdsnws = merge(local.health_tcp, {
    command = ["CMD-SHELL", "python3 -c 'import socket; socket.create_connection((\"127.0.0.1\",8080),2).close()'"]
  })
  health_slarchive = merge(local.health_tcp, {
    command = ["CMD-SHELL", "python3 -c \"import os,sys; n='slarchive'; sys.exit(0 if any(p.isdigit() and open('/proc/%s/comm'%p).read().strip()==n for p in os.listdir('/proc')) else 1)\""]
  })
  health_processor = {
    for name in local.processors : name => merge(local.health_tcp, {
      command = ["CMD-SHELL", "pgrep -f '${name} --console' >/dev/null"]
    })
  }
}

resource "aws_ecs_task_definition" "scmaster" {
  family                   = "${local.name}-scmaster"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name             = "scmaster"
    image            = local.image_scmaster
    essential        = true
    command          = ["bash", "-c", "mkdir -p /home/sysop/seiscomp/var/run && exec /docker/run-scmaster.sh"]
    environment      = concat(local.common_env, local.station_feed, [
      { name = "STATION_KEY_BINDINGS", value = "global:all,scautopick:default,scautoloc:default,scamp:default,scmag:default,scqc:default" },
    ])
    secrets          = local.db_secret
    portMappings     = [{ containerPort = 18180, protocol = "tcp" }]
    logConfiguration = local.log_cfg
    healthCheck      = merge(local.health_scmaster, { startPeriod = 300 })
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "seedlink" {
  family                   = "${local.name}-seedlink"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name             = "seedlink"
    image            = local.image_seedlink
    essential        = true
    user             = "0:0"
    command          = ["bash", "-c", "mkdir -p /home/sysop/seiscomp/var/run && exec /docker/run-seedlink.sh"]
    environment = concat(local.common_env, local.station_feed, [
      { name = "STATION_KEY_BINDINGS", value = "global:all,seedlink:geofon" },
    ])
    secrets          = local.db_secret
    portMappings     = [{ containerPort = 18000, protocol = "tcp" }]
    logConfiguration = local.log_cfg
    healthCheck      = merge(local.health_seedlink, { startPeriod = 300 })
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "slarchive" {
  family                   = "${local.name}-slarchive"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name        = "slarchive"
    image       = local.image_slarchive
    essential   = true
    user        = "0:0"
    command     = ["bash", "-c", "mkdir -p /home/sysop/seiscomp/var/run && exec /docker/run-slarchive.sh"]
    environment = concat(local.common_env, local.station_feed, [
      { name = "STATION_KEY_BINDINGS", value = "global:all,slarchive:week" },
    ])
    secrets     = local.db_secret
    mountPoints = [{
      sourceVolume  = "sds"
      containerPath = "/home/sysop/seiscomp/var/lib/archive"
      readOnly      = false
    }]
    logConfiguration = local.log_cfg
    healthCheck      = local.health_slarchive
  }])

  volume {
    name = "sds"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sds.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sds.id
        iam             = "ENABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "fdsnws" {
  family                   = "${local.name}-fdsnws"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name         = "fdsnws"
    image        = local.image_fdsnws
    essential    = true
    user         = "0:0"
    command      = ["bash", "-c", "mkdir -p /home/sysop/seiscomp/var/run && exec /docker/run-fdsnws.sh"]
    environment  = local.stations_env
    secrets      = local.db_secret
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    mountPoints = [{
      sourceVolume  = "sds"
      containerPath = "/home/sysop/seiscomp/var/lib/archive"
      readOnly      = true
    }]
    logConfiguration = local.log_cfg
    healthCheck      = local.health_fdsnws
  }])

  volume {
    name = "sds"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sds.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sds.id
        iam             = "ENABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "processor" {
  for_each                 = local.processors
  family                   = "${local.name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name             = each.key
    image            = local.image_processor[each.key]
    essential        = true
    user             = "0:0"
    entryPoint       = ["bash", "-c"]
    command          = ["mkdir -p /home/sysop/seiscomp/var/run /home/sysop/seiscomp/var/log && chown -R sysop:sysop /home/sysop/seiscomp/var && exec runuser -u sysop -- /docker/run-processor.sh"]
    environment      = local.stations_env
    secrets          = local.db_secret
    logConfiguration = local.log_cfg
    healthCheck      = local.health_processor[each.key]
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "scmaster" {
  count           = var.deploy_services ? 1 : 0
  name            = "scmaster"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.scmaster.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = aws_subnet.app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.scmaster.arn
  }

  depends_on = [aws_nat_gateway.this, aws_vpc_endpoint.interface]
}

resource "aws_ecs_service" "seedlink" {
  count           = var.deploy_services ? 1 : 0
  name            = "seedlink"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.seedlink.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = aws_subnet.app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.seedlink.arn
  }

  depends_on = [
    aws_ecs_service.scmaster,
    aws_nat_gateway.this,
    aws_vpc_endpoint.interface,
  ]
}

resource "aws_ecs_service" "slarchive" {
  count           = var.deploy_services ? 1 : 0
  name            = "slarchive"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.slarchive.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = aws_subnet.app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.seedlink, aws_efs_mount_target.sds]
}

resource "aws_ecs_service" "fdsnws" {
  count           = var.deploy_services ? 1 : 0
  name            = "fdsnws"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.fdsnws.arn
  desired_count   = var.fdsnws_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 300
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = aws_subnet.app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fdsnws[0].arn
    container_name   = "fdsnws"
    container_port   = 8080
  }

  depends_on = [aws_ecs_service.slarchive, aws_lb_listener.fdsnws]
}

resource "aws_ecs_service" "processor" {
  for_each        = var.deploy_services ? local.processors : toset([])
  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.processor[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = aws_subnet.app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.scmaster, aws_ecs_service.seedlink]
}
