data aws_ami pcs_slurm_x64 {
  most_recent = true

  filter {
    name   = "name"
    values = [ "aws-pcs-sample_ami-amzn2-x86_64-slurm-24.05*" ]
  }
   owners = ["amazon"]
}

data aws_ami pcs_slurm_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = [ "aws-pcs-sample_ami-amzn2-arm64-slurm-24.05*" ]
  }
   owners = ["amazon"]
}

# output "x64_ami_id" {
#   value = data.aws_ami.pcs_slurm_x64.id
# }

# output "arm64_ami_id" {
#   value = data.aws_ami.pcs_slurm_arm64.id
# }
