variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_client_subnet" {
  type        = string
  description = "CIDR block for the client subnet"
}
variable "cidr_rds_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for RDS subnets"
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
variable "db_client_az" {
  type        = string
  description = "Availability zone for the database client"
}
variable "db_client_private_ip" {
  type        = string
  description = "Private IP address"
}
variable "db_client_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "db_client_cloud_init_script" {
  type        = string
  description = "Path to cloud-init script"
}
variable "aurora_subnets_azs" {
  type        = list(string)
  description = "List of availability zones for Aurora subnets"
}
variable "aurora_mysql_db_identifier" {
  type        = string
  description = "Aurora instance identifier"
}
variable "aurora_mysql_cluster_identifier" {
  type        = string
  description = "Aurora cluster identifier"
}
variable "aurora_mysql_engine_version" {
  type        = string
  description = "aurora_mysql_engine_version configuration"
}
variable "aurora_mysql_username" {
  type        = string
  description = "Database master username"
}
variable "aurora_mysql_db_name" {
  type        = string
  description = "Database name"
}
variable "aurora_mysql_size_in_gbs" {
  type        = number
  description = "Allocated storage size in GB"
}
variable "aurora_mysql_serverless_v2_min_acu" {
  type        = number
  description = "Aurora Serverless v2 ACU capacity"
}
variable "aurora_mysql_serverless_v2_max_acu" {
  type        = number
  description = "Aurora Serverless v2 ACU capacity"
}
