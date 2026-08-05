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
  description = "List of authorized public IPv4 CIDR blocks for SSH ingress rules"

  validation {
    condition = length(var.authorized_ips) > 0 && alltrue([
      for cidr in var.authorized_ips : can(cidrnetmask(cidr))
    ])
    error_message = "authorized_ips must contain at least one valid IPv4 CIDR block, such as 203.0.113.10/32. Include the public egress IP of the machine running Terraform."
  }
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
variable "postgresql_identifier" {
  type        = string
  description = "Database identifier"
}
variable "postgresql_instance_class" {
  type        = string
  description = "Database instance class"
}
variable "postgresql_size_in_gbs" {
  type        = number
  description = "Allocated storage size in GB"
}
variable "postgresql_max_size_in_gbs" {
  type        = number
  description = "Maximum allocated storage size in GB"
}
variable "postgresql_db_name" {
  type        = string
  description = "Database name"
}
variable "postgresql_version" {
  type        = string
  description = "Database engine version"
}
variable "postgresql_storage_type" {
  type        = string
  description = "PostgreSQL storage type"
}