variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "authorized_ips_v6" {
  type        = list(string)
  description = "List of authorized public IPv6 CIDR blocks for ingress rules"
}
variable "inst1_type" {
  type        = string
  description = "EC2 instance type"
}
variable "inst2_type" {
  type        = string
  description = "EC2 instance type"
}
variable "arch" {
  type        = string
  description = "CPU architecture (arm64 or x86_64)"
}
variable "az1" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "az2" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "public_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "private_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "cloud_init_script_al" {
  type        = string
  description = "Path to cloud-init script"
}
