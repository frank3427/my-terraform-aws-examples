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
variable "cidr_subnet2" {
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
variable "az2" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "al2_private_ip" {
  type        = string
  description = "Private IP address"
}
variable "al2_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "al2_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "oracle_identifier" {
  type        = string
  description = "Database identifier"
}
variable "oracle_instance_class" {
  type        = string
  description = "Database instance class"
}
variable "oracle_edition" {
  type        = string
  description = "Oracle database configuration parameter"
}
variable "oracle_charset" {
  type        = string
  description = "Oracle database configuration parameter"
}
variable "oracle_size_in_gbs" {
  type        = number
  description = "Allocated storage size in GB"
}
variable "oracle_max_size_in_gbs" {
  type        = number
  description = "Maximum allocated storage size in GB"
}
variable "oracle_sid" {
  type        = string
  description = "Oracle database configuration parameter"
}
variable "oracle_version" {
  type        = string
  description = "Database engine version"
}
variable "oracle_license_model" {
  type        = string
  description = "Oracle database configuration parameter"
}
