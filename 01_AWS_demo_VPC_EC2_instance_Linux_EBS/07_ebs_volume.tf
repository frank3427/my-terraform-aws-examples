# ------ Create an EBS volume
resource aws_ebs_volume demo01_inst1_vol1 {
  availability_zone = "${var.aws_region}${var.az}"
  size              = 20        # size in GBs
  type              = "gp3"     # can be: gp2, gp3, io1, io2, sc1, st1
  encrypted         = true      # use default KMS key aws/ebs
  tags              = { Name = "demo01-inst1-vol1" }  
}

# ------ Attach the EBS volume to the EC2 instance
resource aws_volume_attachment demo01_inst1_vol1 {
  volume_id   = aws_ebs_volume.demo01_inst1_vol1.id
  instance_id = aws_instance.demo01_inst1.id
  device_name = var.ebs_device_name          # recommended for EBS volumes: /dev/sd[f-p]
}