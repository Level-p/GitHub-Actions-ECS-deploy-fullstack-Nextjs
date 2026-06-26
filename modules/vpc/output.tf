output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}


output "public_subnet_ids" {
  value = { for k, s in aws_subnet.public_subs : k => s.id }
}

output "private_subnet_ids" {
  value = { for k, s in aws_subnet.private_subs : k => s.id }
}

output "public_key" {
  value = aws_key_pair.public-key.key_name
  sensitive = true
}

output "private_key" {
  value = tls_private_key.key.private_key_pem
  sensitive = true
}

output "sgout" {
  value = aws_security_group.ecs_sg.id
}