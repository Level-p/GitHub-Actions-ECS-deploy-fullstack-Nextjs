# ==========================
# APPLICATION LOAD BALANCER
# ==========================
resource "aws_lb" "prod_LB" {
  name               = "ecs-prod-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.prod_elb_sg.id]
  subnets            = var.public_subnets

  tags = {
    Name = "ecs-prod-lb"
  }
}

# ==========================
# ALB SECURITY GROUP
# ==========================
resource "aws_security_group" "prod_elb_sg" {
  name        = "ecs-prod-elb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-prod-elb-sg"
  }
}

# ==========================
# TARGET GROUP (FARGATE)
# ==========================
resource "aws_lb_target_group" "prod_target_group" {
  name        = "ecs-prod-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "ecs-prod-tg"
  }
}

# ==========================
# HTTP LISTENER (REDIRECT)
# ==========================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.prod_LB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ==========================
# HTTPS LISTENER
# ==========================
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.prod_LB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_target_group.arn
  }
}

# ==========================
# ROUTE 53 RECORD
# ==========================
data "aws_route53_zone" "zone" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.prod_LB.dns_name
    zone_id                = aws_lb.prod_LB.zone_id
    evaluate_target_health = true
  }
}