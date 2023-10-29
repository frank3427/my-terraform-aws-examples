# ------ Create an EBS volume
resource awscc_ec2_volume demo101_inst1_vol1 {
  availability_zone = "${var.aws_region}${var.az}"
  size              = 20        # size in GBs
  volume_type       = "gp3"     # can be: gp2, gp3, io1, io2, sc1, st1
  encrypted         = true      # use default KMS key aws/ebs
  tags              = [{ key = "Name", value = "demo101-inst1-vol1" }]
}

# ------ Attach the EBS volume to the EC2 instance
resource awscc_ec2_volume_attachment demo101_inst1_vol1 {
  volume_id   = awscc_ec2_volume.demo101_inst1_vol1.id
  instance_id = aws_instance.demo101_inst1.id
  device      = var.ebs_device_name          # recommended for EBS volumes: /dev/sd[f-p]
}