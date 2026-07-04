variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet1" {
  type        = string
  description = "CIDR block for the subnet"
}
variable "cidr_subnet2_efa" {
  type        = string
  description = "cidr_subnet2_efa configuration"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "nb_instances" {
  type        = number
  description = "Number of EC2 instances"
}
variable "inst_private_ip" {
  type        = list(string)
  description = "List of private IP addresses for the EC2 instances"
}
variable "inst_private_ip_efa" {
  type        = list(string)
  description = "List of private IP addresses for EFA interfaces"
}
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "arch" {
  type        = string
  description = "CPU architecture (arm64 or x86_64)"
}
variable "linux" {
  type        = string
  description = "Linux distribution"
}
variable "az" {
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
variable "cloud_init_script_ubuntu" {
  type        = string
  description = "Path to cloud-init script"
}
