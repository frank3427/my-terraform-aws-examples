variable "aws_region" {
  type = string
}
variable "cidr_vpc" {
  type = string
  validation {
    condition     = can(cidrhost(var.cidr_vpc, 0))
    error_message = "The cidr_vpc must be a valid CIDR block."
  }
}
variable "cidr_subnet_public_bastion" {
  type = string
  validation {
    condition     = can(cidrhost(var.cidr_subnet_public_bastion, 0))
    error_message = "The cidr_subnet_public_bastion must be a valid CIDR block."
  }
}
variable "cidr_subnets_public_lb" {
  type = list(string)
  validation {
    condition     = alltrue([for cidr in var.cidr_subnets_public_lb : can(cidrhost(cidr, 0))])
    error_message = "All values in cidr_subnets_public_lb must be valid CIDR blocks."
  }
}
variable "cidr_subnets_private_websrv" {
  type = list(string)
  validation {
    condition     = alltrue([for cidr in var.cidr_subnets_private_websrv : can(cidrhost(cidr, 0))])
    error_message = "All values in cidr_subnets_private_websrv must be valid CIDR blocks."
  }
}
variable "authorized_ips" {
  type = list(string)
}
variable "websrv_az" {
  type = list(string)
}
variable "websrv_inst_type" {
  type = string
}
variable "websrv_public_sshkey_path" {
  type = string
}
variable "websrv_private_sshkey_path" {
  type = string
}
variable "websrv_cloud_init_script" {
  type = string
}
variable "bastion_az" {
  type = string
}
variable "bastion_inst_type" {
  type = string
}
variable "bastion_public_sshkey_path" {
  type = string
}
variable "bastion_private_sshkey_path" {
  type = string
}
variable "bastion_cloud_init_script" {
  type = string
}
variable "alb_use_waf" {
  type = bool
}