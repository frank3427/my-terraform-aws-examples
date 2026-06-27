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
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "public_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "private_sshkey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "az" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "private_ip" {
  type        = string
  description = "Private IP address for the EC2 instance"
}
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "efs_mount_point" {
  type        = string
  description = "Mount point for EFS filesystem"
}
