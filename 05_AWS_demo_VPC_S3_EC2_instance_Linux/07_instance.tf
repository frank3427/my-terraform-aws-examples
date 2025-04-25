# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo05_inst1 {
  instance = aws_instance.demo05_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo05-inst1" }
}

# ------ Create a SSH key pair from public key file
resource aws_key_pair demo05_kp1 {
  key_name   = "demo05-kp1"
  public_key = file(var.public_sshkey_path)
}

# ------ Create an EC2 instance
resource aws_instance demo05_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = data.aws_ami.al2_x86-64.id
  key_name               = aws_key_pair.demo05_kp1.id
  subnet_id              = aws_subnet.demo05_public.id
  vpc_security_group_ids = [ aws_security_group.demo05_sg1.id ] 
  tags                   = { Name = "demo05-inst1" }
  user_data_base64       = base64encode(file(var.cloud_init_script))
  iam_instance_profile   = aws_iam_instance_profile.demo05.id
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo05-inst1-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username = "ec2-user"   # ec2-user or ubuntu
  bucket_name = aws_s3_bucket.demo05.id
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo05_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh demo05"
Host demo05
        Hostname ${aws_eip.demo05_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}

---- Once connected, you can execute "aws s3" commands thanks to new IAM role assigned to the EC2 instance
aws s3 ls
echo test > test-file.txt
aws s3 cp test-file.txt s3://${local.bucket_name} 
aws s3 ls s3://${local.bucket_name}
aws s3 rm s3://${local.bucket_name}/test-file.txt
aws s3 ls s3://${local.bucket_name}

---- You can also use Mountpoint for S3
sudo mkdir /mnt/s3
sudo mount-s3 ${local.bucket_name} /mnt/s3

Note: you can use the following command to create a 2 GB te tfile
dd if=/dev/random of=big-test-file bs=1024k count=2048

---- The bucket policy associated to this S3 bucket should block accesses not coming from the S3 gateway endpoint
From your local laptop, the following commands should fail because of the bucket policy:
echo test > test-file2.txt
aws s3 cp test-file2.txt s3://${local.bucket_name} 
aws s3 rm s3://${local.bucket_name}/test-file2.txt


EOF
}
