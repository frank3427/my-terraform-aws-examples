# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]    # use old 2022 AMIs to have missing patches
  }
   owners = ["amazon"]
}

# ---- Is logging to S3 set in Session Manager preferences ? if so, get S3 bucket for Session Manager logs
# ---- Is logging to CloudWatch set in Session Manager preferences ? if so, get log group name for Session Manager logs
data aws_ssm_document session_manager_prefs {
  name            = "SSM-SessionManagerRunShell"
  document_format = "JSON"
}

locals {
  session_manager_s3_bucket = try(
    jsondecode(data.aws_ssm_document.session_manager_prefs.content).inputs.s3BucketName,
    ""
  )
  session_manager_cw_log_grp = try(
    jsondecode(data.aws_ssm_document.session_manager_prefs.content).inputs.cloudWatchLogGroupName,
    ""
  )
}
# output "session_manager_settings" {
#   value = jsondecode(data.aws_ssm_document.session_manager_prefs.content)
# }
