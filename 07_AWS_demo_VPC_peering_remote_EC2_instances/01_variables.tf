variable "aws_region1" {
  type        = string
  description = "AWS region"
}
variable "aws_region2" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc_r1" {
  type        = string
  description = "CIDR block for the VPC in region"
}
variable "cidr_public_r1" {
  type        = string
  description = "CIDR block for the public subnet in region"
}
variable "cidr_vpc_r2" {
  type        = string
  description = "CIDR block for the VPC in region"
}
variable "cidr_public_r2" {
  type        = string
  description = "CIDR block for the public subnet in region"
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
