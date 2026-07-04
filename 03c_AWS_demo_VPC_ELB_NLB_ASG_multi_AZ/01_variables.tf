variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet_public" {
  type        = list(string)
  description = "CIDR block for the public subnet"
}
variable "cidr_subnet_private" {
  type        = list(string)
  description = "CIDR block for the private subnet"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "nb_az" {
  type        = number
  description = "Number of availability zones"
}
variable "az" {
  type        = list(string)
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "websrv_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "websrv_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
