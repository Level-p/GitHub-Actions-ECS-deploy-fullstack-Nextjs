output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}

output "ecs_cluster_name" {
 value = module.cluster.ecs_cluster_name
}

output "ecs_service_name" {
    value = module.service.ecs_service_name
}