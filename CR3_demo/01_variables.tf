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
variable "cidr_bastion_r1" {
  type        = string
  description = "CIDR block for the bastion subnet in region"
}
variable "cidrs_alb_r1" {
  type        = list(string)
  description = "List of CIDR blocks for ALB subnets in region 1"
}
variable "cidrs_websrv_r1" {
  type        = list(string)
  description = "List of CIDR blocks for web server subnets in region 1"
}
variable "cidr_vpc_r2" {
  type        = string
  description = "CIDR block for the VPC in region"
}
variable "cidr_public_r2" {
  type        = string
  description = "CIDR block for the public subnet in region"
}
variable "priv_ip_ws_dr" {
  type        = string
  description = "Private IP address"
}
variable "priv_ip_bastion" {
  type        = string
  description = "Private IP address"
}
variable "priv_ip_ws" {
  type        = list(string)
  description = "List of private IP addresses for web servers"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "az_bastion" {
  type        = string
  description = "Availability zone for the bastion host"
}
variable "az_dr" {
  type        = string
  description = "Availability zone for disaster recovery"
}
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "public_sshkey_path" {
  type        = list(string)
  description = "Path to SSH key file"
}
variable "private_sshkey_path" {
  type        = list(string)
  description = "Path to SSH key file"
}
variable "cloud_init_script_bastion" {
  type        = string
  description = "Path to cloud-init script"
}
variable "cloud_init_script_websrv" {
  type        = string
  description = "Path to cloud-init script"
}
variable "cloud_init_script_dr" {
  type        = string
  description = "Path to cloud-init script"
}
variable "web_page_zip" {
  type        = string
  description = "Path to web page ZIP file"
}
variable "efs_mount_point" {
  type        = string
  description = "Mount point for EFS filesystem"
}
variable "dns_name_primary" {
  type        = string
  description = "DNS configuration parameter"
}
variable "dns_name_secondary" {
  type        = string
  description = "DNS configuration parameter"
}
variable "dns_domain" {
  type        = string
  description = "DNS configuration parameter"
}
variable "dns_zone_id" {
  type        = string
  description = "DNS configuration parameter"
}
