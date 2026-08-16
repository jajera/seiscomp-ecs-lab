resource "aws_lb" "fdsnws" {
  count              = var.deploy_services ? 1 : 0
  name               = "${local.name}-fdsnws"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.app[*].id
}

resource "aws_lb_target_group" "fdsnws" {
  count       = var.deploy_services ? 1 : 0
  name        = "${local.name}-fdsnws"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    path                = "/fdsnws/station/1/version"
    port                = "8080"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200-499"
  }
}

resource "aws_lb_listener" "fdsnws" {
  count             = var.deploy_services ? 1 : 0
  load_balancer_arn = aws_lb.fdsnws[0].arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fdsnws[0].arn
  }
}

