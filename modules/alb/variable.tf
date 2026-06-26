variable "name" {}
variable "vpc_id" {}
variable "key_name" {}
variable "public_subnets" {
  description = "Subnet ID where the master node will be deployed"
  type        = list(string)
}
variable "acm_cert_arn" {}
variable "domain" {}