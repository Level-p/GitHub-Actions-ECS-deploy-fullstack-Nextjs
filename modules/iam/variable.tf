variable "ecs_task_execution_role_name" {
  description = "ECS Task Execution Role Name"
  type        = string
  default     = "ecsTaskExecutionRole"
}

variable "ecs_task_role_name" {
  description = "ECS Task Role Name"
  type        = string
  default     = "ecsTaskRole"
}