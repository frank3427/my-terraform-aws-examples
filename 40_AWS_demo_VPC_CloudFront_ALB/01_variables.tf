variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet_public_bastion" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "cidr_subnets_public_lb" {
  type        = list(string)
  description = "List of CIDR blocks for subnets"
}
variable "cidr_subnets_private_websrv" {
  type        = list(string)
  description = "List of CIDR blocks for subnets"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "websrv_nb_instances" {
  type        = number
  description = "Number of web server instances"
}
variable "websrv_az" {
  type        = list(string)
  description = "Availability zone for web servers"
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
variable "bastion_az" {
  type        = string
  description = "Availability zone for the bastion host"
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
