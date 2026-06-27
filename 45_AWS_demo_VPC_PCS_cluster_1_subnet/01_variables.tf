variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "cidr_subnet_public" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "az_subnet" {
  type        = string
  description = "Availability zone for the subnet"
}
variable "authorized_ips" {
  type        = list(string)
  description = "List of authorized public IP CIDR blocks for ingress rules"
}
variable "cpt_nodes_count" {
  type        = number
  description = "Number of compute nodes"
}
variable "cpt_nodes_inst_type" {
  type        = string
  description = "EC2 instance type"
}
variable "cpt_nodes_public_sshkey_path" {
  type        = string
  description = "Path to public SSH key file"
}
variable "cpt_nodes_private_sshkey_path" {
  type        = string
  description = "Path to private SSH key file"
}
variable "cpt_nodes_cloud_init_template" {
  type        = string
  description = "Path to cloud-init template"
}
variable "pcs_slurm_version" {
  type        = string
  description = "PCS Slurm version"
}
variable "efs_mountpoint" {
  type        = string
  description = "Mount point for EFS filesystem"
}
variable "fsx_lustre_mountpoint" {
  type        = string
  description = "Mount point for FSx Lustre filesystem"
}
variable "fsx_lustre_size_gb" {
  type        = number
  description = "FSx Lustre filesystem size in GB"
}
variable "fsx_lustre_version" {
  type        = string
  description = "FSx Lustre filesystem version"
}
variable "scripts_dir" {
  type        = string
  description = "Path to scripts directory"
}
variable "slurm_queue" {
  type        = string
  description = "Slurm queue name"
}
