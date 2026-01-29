variable "aws_region" {}
variable "cidr_vpc" {}
variable "cidr_subnet1" {}
variable "authorized_ips" {}
variable "inst1_type" {}
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
    condition     = contains(["al2", "al2023", "ubuntu22", "ubuntu24", "sles15", "rhel9"], var.linux_os_version)
    error_message = "Valid values for linux_os_version are al2, al2023, ubuntu22, ubuntu24, sles15, rhel9"
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
variable "inst1_private_ip" {}
variable "public_sshkey_path" {}
variable "private_sshkey_path" {}
variable "cloud_init_script_al" {}
variable "cloud_init_script_ubuntu" {}
variable "cloud_init_script_sles" {}
variable "cloud_init_script_rhel" {}
variable "ebs_device_name" {}
