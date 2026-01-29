variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnets_public" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}
variable "cidr_subnets_private" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}
variable "inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}
variable "cloud_init_script_al2" {
  type        = string
  description = "Path to cloud-init script for Amazon Linux 2"
}