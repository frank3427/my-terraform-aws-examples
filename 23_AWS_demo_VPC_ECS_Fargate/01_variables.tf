variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "az_for_fis" {
  type        = string
  description = "Availability zone for FIS experiment"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnets_public" {
  type        = list(string)
  description = "List of CIDR blocks for subnets"
}
variable "cidr_subnets_private" {
  type        = list(string)
  description = "List of CIDR blocks for subnets"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
