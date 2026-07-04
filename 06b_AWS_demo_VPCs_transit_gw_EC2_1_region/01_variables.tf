variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidrs_vpc" {
  type        = list(string)
  description = "List of CIDR blocks for the VPCs"
}
variable "cidrs_subnet_ec2" {
  type        = list(string)
  description = "List of CIDR blocks for EC2 subnets"
}
variable "cidrs_subnet_tgw" {
  type        = list(string)
  description = "List of CIDR blocks for Transit Gateway subnets"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "az" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "public_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "private_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
