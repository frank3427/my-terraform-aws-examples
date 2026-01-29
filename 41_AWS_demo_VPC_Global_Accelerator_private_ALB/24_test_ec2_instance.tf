# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for test persistent across stop/start
resource "aws_eip" "demo41_test" {
  region   = var.test_region
  instance = aws_instance.demo41_test.id
  domain   = "vpc"
  tags     = { Name = "demo41-test" }
}

# ------ Create an EC2 instance for test
resource "aws_instance" "demo41_test" {
  region = var.test_region
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.test_inst_type
  ami                    = data.aws_ami.test_al2_arm64.id
  key_name               = aws_key_pair.demo41_test.id
  subnet_id              = aws_subnet.demo41-test-public[0].id
  vpc_security_group_ids = [aws_security_group.demo41_sg_test.id]
  tags                   = { Name = "demo41-test" }
  user_data_base64       = base64encode(file(var.test_cloud_init_script))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo41-test-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo41_sg_test" {
  region      = var.test_region
  name        = "demo41-sg-test"
  description = "Description for demo41-sg-test"
  vpc_id      = aws_vpc.demo41-test.id
  tags        = { Name = "demo41-sg-test" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
