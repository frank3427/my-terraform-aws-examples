variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "acct1_profile" {
  type        = string
  description = "AWS CLI profile name"
}
variable "acct2_profile" {
  type        = string
  description = "AWS CLI profile name"
}
variable "acct1_pvd_cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "acct1_pvd_cidr_subnet_public" {
  type        = string
  description = "CIDR block for the subnet"
}
variable "acct1_pvd_cidr_subnet_private" {
  type        = string
  description = "CIDR block for the subnet"
}
variable "acct2_csm_cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "acct2_csm_cidr_subnet_public" {
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
variable "acct1_pvd_websrv_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "acct1_pvd_websrv_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "acct1_pvd_websrv_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "acct1_pvd_websrv_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "acct1_pvd_bastion_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "acct1_pvd_bastion_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "acct1_pvd_bastion_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "acct1_pvd_bastion_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "acct2_csm_bastion_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "acct2_csm_bastion_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "acct2_csm_bastion_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "acct2_csm_bastion_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
