locals {
  name = "practice-ecs"
}

data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false

}
#calling acm certificate
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "nextjs4-secrets"
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    GOOGLE_CLIENT_ID = var.GOOGLE_CLIENT_ID
    GOOGLE_CLIENT_SECRET = var.GOOGLE_CLIENT_SECRET
    NEXTAUTH_SECRET = var.NEXTAUTH_SECRET
    NEXTAUTH_URL = var.NEXTAUTH_URL
    NEXT_PUBLIC_FIREBASE_API_KEY = var.NEXT_PUBLIC_FIREBASE_API_KEY
  })
}

resource "aws_acm_certificate" "varsitix-acm-cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name}-acm-cert"
  }
}

data "aws_route53_zone" "varsitix-acp-zone" {
  name         = var.domain_name
  private_zone = false
}

# Fetch DNS Validation Records for ACM Certificate
resource "aws_route53_record" "acm_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.varsitix-acm-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  # Create DNS Validation Record for ACM Certificate
  zone_id         = data.aws_route53_zone.varsitix-acp-zone.zone_id
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  depends_on      = [aws_acm_certificate.varsitix-acm-cert]
}

# Validate the ACM Certificate after DNS Record Creation
resource "aws_acm_certificate_validation" "varsitix_cert_validation" {
  certificate_arn         = aws_acm_certificate.varsitix-acm-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_record : record.fqdn]
  depends_on              = [aws_acm_certificate.varsitix-acm-cert]
}

module "vpc" {
  source              = "./modules/vpc"
  name                = local.name
  acm_certificate_arn = aws_acm_certificate.varsitix-acm-cert.arn
}

module "alb" {
  source       = "./modules/alb"
  key_name     = module.vpc.private_key
  name         = local.name
  acm_cert_arn = aws_acm_certificate.varsitix-acm-cert.arn
  public_subnets = [
    module.vpc.public_subnet_ids["pub2"],
    module.vpc.public_subnet_ids["pub3"]
  ]
  domain = var.domain_name
  vpc_id = module.vpc.vpc_id
}

module "ecr" {
  source = "./modules/ecr"
}

module "autoscale" {
  source       = "./modules/ecs/Autoscaling"
  max_capacity = 5
  min_capacity = 1
  cluster_name = module.cluster.ecs_cluster_name
  ecs_service_name = module.service.ecs_service_name
}

module "cluster" {
  source = "./modules/ecs/Cluster"
  name   = "${local.name}-cluster"
}

module "service" {
  source = "./modules/ecs/Service"
  subnets_id = [
    module.vpc.private_subnet_ids["pri3"],
    module.vpc.private_subnet_ids["pri3"]
  ]
  container_name      = "appContainer"
  container_port      = 3000
  ecs_cluster_id      = module.cluster.ecs_cluster_id
  arn_target_group    = module.alb.arn_target_group
  arn_task_definition = module.task_definition.arn_task_definition
  name                = "${local.name}-service"
  iam_role_ecs = module.iam.ecs_task_role_arn
  desired_tasks       = 1
  arn_security_group  = module.vpc.sgout
}

module "task_definition" {
  source             = "./modules/ecs/TaskDefinition"
  cpu                = 2048
  memory             = 4096
  region             = "eu-west-2"
  docker_repo        = module.ecr.ecr_repository_url
  container_port     = 3000
  container_name     = "appContainer"
  name               = "${local.name}-task-def"
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  secret_arn = aws_secretsmanager_secret.app_secrets.arn
  task_role_arn = module.iam.ecs_task_role_arn
}

module "iam" {
  source = "./modules/iam"
}


variable "domain_name" {
  default = "mfon21.space"
}
