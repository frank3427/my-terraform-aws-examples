variable "aws_region1" {}
variable "aws_region2" {}
variable "cidr_vpc_r1" {}
variable "cidr_bastion_r1" {}
variable "cidrs_alb_r1" {}
variable "cidrs_websrv_r1" {}
variable "cidr_vpc_r2" {}
variable "cidr_public_r2" {}
variable "priv_ip_ws_dr" {}
variable "priv_ip_bastion" {}
variable "priv_ip_ws" {}
variable "authorized_ips" {}
variable "az_bastion" {}
variable "az_dr" {}
variable "inst_type" {}
variable "public_sshkey_path" {}
variable "private_sshkey_path" {}
variable "cloud_init_script_bastion" {}
variable "cloud_init_script_websrv" {}
variable "cloud_init_script_dr" {}
variable "web_page_zip" {}
variable "efs_mount_point" {}
variable "dns_name_primary" {}
variable "dns_name_secondary" {}
variable "dns_domain" {}
variable "dns_zone_id" {}

variable "inst_type_db" {
  description = "Instance type for MariaDB servers"
  type        = string
  default     = "t3.micro" 
}

variable "db_ebs_device_name" {
  description = "EBS device name for MariaDB data volume"
  type        = string
  default     = "/dev/sdf"
}

variable "db_ebs_volume_size" {
  description = "Size of the EBS volume for MariaDB data (in GB)"
  type        = number
  default     = 20
}
