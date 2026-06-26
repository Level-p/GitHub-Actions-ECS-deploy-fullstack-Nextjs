/*====================================
      AWS ECS Task Definition
=====================================*/

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/task-definition-${var.name}"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "task-definition-${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = var.docker_repo

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      
      environment = [
      {
        name  = "GOOGLE_CLIENT_ID"
        value = "${var.secret_arn}:GOOGLE_CLIENT_ID::"
      },
      {
        name  = "GOOGLE_CLIENT_SECRET"
        value = "${var.secret_arn}:GOOGLE_CLIENT_SECRET::"
      },
      {
        name      = "NEXTAUTH_SECRET"
         value = "${var.secret_arn}:NEXTAUTH_SECRET::"
      },
      {
        name      = "NEXTAUTH_URL"
        value = "${var.secret_arn}:NEXTAUTH_URL::"
      },
      {
        name      = "NEXT_PUBLIC_FIREBASE_API_KEY"
        value = "${var.secret_arn}:NEXT_PUBLIC_FIREBASE_API_KEY::"
      }
    ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.ecs_log_group
  ]
}