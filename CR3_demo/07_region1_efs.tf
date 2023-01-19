# ----- Create an EFS filesystem
resource aws_efs_file_system cr3_r1 {
  provider       = aws.r1
  creation_token = "cr3-r1-efs-fs1"

  # optional parameters
  #availability_zone_name = "${var.aws_region}${var.az}"     # for OneZone only
  performance_mode       = "generalPurpose" # "generalPurpose" (default) or "maxIO"
  throughput_mode        = "bursting"       #  bursting (default), provisioned. When using provisioned, also set provisioned_throughput_in_mibps.
  tags                   = { Name = "cr3-r1-efs-fs1" }
  encrypted              = true
  # kms_key_id             = "..arn"
#   lifecycle_policy {
#     transition_to_ia                    = "AFTER_30_DAYS"   # AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS.
#     transition_to_primary_storage_class = "AFTER_1_ACCESS"  # AFTER_1_ACCESS
#   }
}

# ------ Create a security group for the EFS filesystem
resource aws_security_group cr3_sg_r1_efs {
  provider    = aws.r1
  name        = "cr3-sg-r1-efs"
  description = "Security group for EFS filesystem in region 1"
  vpc_id      = aws_vpc.cr3_r1.id
  tags        = { Name = "cr3-sg-r1-efs" }

  # ingress rule: allow NFS from private subnets
  ingress {
    description = "allow NFS access from VPC (TCP)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc_r1 ]
  }

  # ingress rule: allow NFS from private subnets
  ingress {
    description = "allow NFS access from VPC (UDP)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = [ var.cidr_vpc_r1 ]
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# ----- Create a mount target for all 3 private subnets
resource aws_efs_mount_target cr3_r1 {
  provider        = aws.r1
  count           = "3"
  file_system_id  = aws_efs_file_system.cr3_r1.id
  subnet_id       = aws_subnet.cr3_private_r1[count.index].id
  security_groups = [ aws_security_group.cr3_sg_r1_efs.id ] 
}