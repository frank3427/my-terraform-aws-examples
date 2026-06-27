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
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "az" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "websrv_private_ips" {
  type        = list(string)
  description = "List of private IP addresses for web servers"
}
variable "websrv_private_ip_vip" {
  type        = string
  description = "Virtual IP address for web servers"
}
variable "websrv_vip_owner" {
  type        = number
  description = "Index of the web server owning the VIP"
}
variable "websrv_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "websrv_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "websrv_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "websrv_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "bastion_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "bastion_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "bastion_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "bastion_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
