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
variable "az" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "public_rsakey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "private_rsakey_path" {
  type        = string
  description = "Path to SSH key file"
}
variable "crypted_pwd_file" {
  type        = string
  description = "Path to encrypted password file"
}
variable "decrypted_pwd_file" {
  type        = string
  description = "Path to decrypted password file"
}
variable "inst1_type" {
  type        = string
  description = "EC2 instance type"
}
