variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet_public" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "cidr_subnet_private" {
  type        = string
  description = "CIDR block for the private subnet"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "az" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "db_client_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "db_client_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "db_client_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "db_client_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
