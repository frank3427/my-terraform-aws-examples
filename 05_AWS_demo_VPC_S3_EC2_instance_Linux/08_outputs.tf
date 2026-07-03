output "ami" {
  value = local.ami
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username    = "ec2-user" # ec2-user or ubuntu
  bucket_name = aws_s3_bucket.demo05.id
}

output "Instance" {
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

Note: you can use the following command to create a 2 GB test tfile
dd if=/dev/random of=big-test-file bs=1024k count=2048

---- The bucket policy associated to this S3 bucket should block accesses not coming from the S3 gateway endpoint
From your local laptop, the following commands should fail because of the bucket policy:
echo test > test-file2.txt
aws s3 cp test-file2.txt s3://${local.bucket_name} 
aws s3 rm s3://${local.bucket_name}/test-file2.txt


EOF
}
