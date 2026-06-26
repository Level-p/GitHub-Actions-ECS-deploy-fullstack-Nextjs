output "prod-sg" {
  value       = aws_security_group.prod_elb_sg.id
  description = "Security group ID for the prod environment"
}

output "laravel_dns" {
  value = aws_lb.prod_LB.dns_name
}

output "arn_target_group" {
  value = aws_lb_target_group.prod_target_group.arn
}