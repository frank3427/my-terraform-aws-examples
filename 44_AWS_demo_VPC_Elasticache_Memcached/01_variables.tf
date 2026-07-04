variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet_pub" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "cidr_subnet_priv" {
  type        = string
  description = "CIDR block for the private subnet"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "inst1_type" {
  type        = string
  description = "EC2 instance type"
}
variable "arch" {
  type        = string
  description = "arm64 for Graviton-based EC2 instances or x86_64 for AMD/Intel based EC2 instances"
  validation {
    condition     = var.arch == "arm64" || var.arch == "x86_64"
    error_message = "Valid values for arch are arm64 and x86_64"
  }
}
variable "linux_os_version" {
  type        = string
  description = "Linux OS version"
  validation {
    condition     = contains(["al2", "al2023", "ubuntu22", "sles15", "rhel9"], var.linux_os_version)
    error_message = "Valid values for linux_os_version are al2, al2023, ubuntu22, sles15, rhel9"
  }
}
variable "az" {
  type        = string
  description = "Availability zone"
  validation {
    condition     = contains(["a", "b", "c"], var.az)
    error_message = "Valid values for az are a, b and c"
  }
}
variable "inst1_private_ip" {
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
variable "cloud_init_script_al" {
  type        = string
  description = "Path to cloud-init script"
}
variable "cloud_init_script_ubuntu" {
  type        = string
  description = "Path to cloud-init script"
}
variable "cloud_init_script_sles" {
  type        = string
  description = "Path to cloud-init script"
}
variable "cloud_init_script_rhel" {
  type        = string
  description = "Path to cloud-init script"
}
variable "memcached_version" {
  type        = string
  description = "Memcached engine version"
}
variable "elasticache_nb_nodes" {
  type        = number
  description = "Number of ElastiCache nodes"
}
variable "elasticache_node_type" {
  type        = string
  description = "Node instance type"
}
