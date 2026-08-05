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
variable "az1" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "az2" {
  type        = string
  description = "Availability zone suffix (e.g., a, b, c)"
}
variable "al2023_private_ip" {
  type        = string
  description = "Private IP address"
}
variable "al2023_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "al2023_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "docdb_identifier" {
  type        = string
  description = "DocumentDB configuration parameter"
}
variable "docdb_user" {
  type        = string
  description = "DocumentDB configuration parameter"
}
variable "docdb_backup_retention" {
  type        = number
  description = "Number of days for DocumentDB backup retention"
}
variable "docdb_backup_window" {
  type        = string
  description = "DocumentDB configuration parameter"
}
variable "docdb_maintenance_window" {
  type        = string
  description = "DocumentDB configuration parameter"
}
variable "docdb_port" {
  type        = number
  description = "Port number for DocumentDB"
}
variable "docdb_instance_type" {
  type        = string
  description = "DocumentDB configuration parameter"
}
variable "docdb_nb_of_instances" {
  type        = number
  description = "Number of DocumentDB instances"
}
variable "docdb_apply_immediately" {
  type        = bool
  description = "Apply DocumentDB changes immediately"
}
