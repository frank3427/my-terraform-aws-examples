variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "account0_profile" {
  type        = string
  description = "AWS CLI profile name for account"
}
variable "account1_profile" {
  type        = string
  description = "AWS CLI profile name for account"
}
variable "account2_profile" {
  type        = string
  description = "AWS CLI profile name for account"
}
variable "acct0_cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "acct0_cidr_subnet1" {
  type        = string
  description = "CIDR block for the subnet"
}
variable "acct1_cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "acct1_cidr_subnet1" {
  type        = string
  description = "CIDR block for the subnet"
}
variable "acct2_cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "acct2_cidr_subnet1" {
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
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "acct0_inst_private_ip" {
  type        = string
  description = "Private IP address for the EC2 instance"
}
variable "acct1_inst_private_ip" {
  type        = string
  description = "Private IP address for the EC2 instance"
}
variable "acct2_inst_private_ip" {
  type        = string
  description = "Private IP address for the EC2 instance"
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
variable "r53_domain" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_sub_domain1" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_sub_domain2" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_host1_in_acct1" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_host2_in_acct2" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_endp_inb_ip1" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_endp_inb_ip2" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_endp_outb_ip1" {
  type        = string
  description = "Route53 configuration parameter"
}
variable "r53_endp_outb_ip2" {
  type        = string
  description = "Route53 configuration parameter"
}
