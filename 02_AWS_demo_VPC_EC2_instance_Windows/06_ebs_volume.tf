# ------ Create an EBS volume
resource aws_ebs_volume demo02_inst1_vol1 {
  availability_zone = "${var.aws_region}${var.az}"
  size              = 40        # size in GBs
  tags              = { Name = "demo02-inst1-vol1" }  
  type              = "gp2"     # can be: gp2, gp3, io1, io2, sc1, st1
  encrypted         = true
}

# ------ Attach the EBS volume to the EC2 instance
resource aws_volume_attachment demo02_inst1_vol1 {
  volume_id   = aws_ebs_volume.demo02_inst1_vol1.id
  instance_id = aws_instance.demo02_inst1.id
  device_name = "/dev/sdf"          # recommended for EBS volumes: /dev/sd[f-p]
}