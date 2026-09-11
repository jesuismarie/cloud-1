# This file contains the main Terraform configuration for provisioning an AWS EC2 instance.

# Define the AWS EC2 Instance
resource "aws_instance" "cloud-1" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.aws_instance_type
  key_name      = aws_key_pair.cloud1.key_name

  tags = {
    Name        = "cloud-1"
    Description = "cloud-1 EC2 instance provisioned by Terraform"
  }

  vpc_security_group_ids = [aws_security_group.cloud1_sg.id]
}

# Define AWS EC2 Instance Key Pair
resource "aws_key_pair" "cloud1" {
  key_name   = "cloud1-key"
  public_key = file(var.ssh_public_key_path)
}

# Define The Security Group for the EC2 Instance
resource "aws_security_group" "cloud1_sg" {
  name        = "cloud-1-sg"
  description = "Security group for cloud-1 instance"

  ingress {
    description = "Allow SSH (22)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP (80)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS (443)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
