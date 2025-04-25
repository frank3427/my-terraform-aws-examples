resource aws_efs_file_system demo45a {
  creation_token         = "demo45a-efs-fs1"
  performance_mode       = "generalPurpose" # "generalPurpose" (default) or "maxIO"
  throughput_mode        = "bursting"       #  bursting (default), provisioned. When using provisioned, also set provisioned_throughput_in_mibps.
  tags                   = { Name = "demo45a-efs-fs1" }
  encrypted              = true
  # kms_key_id             = "..arn"
#   lifecycle_policy {
#     transition_to_ia                    = "AFTER_30_DAYS"   # AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS.
#     transition_to_primary_storage_class = "AFTER_1_ACCESS"  # AFTER_1_ACCESS
#   }
}

resource aws_efs_mount_target demo45a {
  file_system_id  = aws_efs_file_system.demo45a.id
  subnet_id       = aws_subnet.demo45a_public.id
  security_groups = [ aws_security_group.demo45a.id ] 
}
