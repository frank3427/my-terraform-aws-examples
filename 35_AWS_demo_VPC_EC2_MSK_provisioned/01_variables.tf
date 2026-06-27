variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for subnets"
}
variable "az_subnets" {
  type        = list(string)
  description = "List of availability zones for subnets"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "inst1_type" {
  type        = string
  description = "EC2 instance type"
}
variable "inst1_arch" {
  type        = string
  description = "inst1_arch configuration"
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
variable "cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "msk_kafka_version" {
  type        = string
  description = "Kafka version for MSK cluster"
}
variable "msk_node_type" {
  type        = string
  description = "Node instance type"
}
variable "msk_ebs_size_gb" {
  type        = number
  description = "EBS volume size in GB for MSK brokers"
}
