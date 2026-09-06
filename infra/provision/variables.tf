# This file contains the variable definitions for the Terraform configuration.

# AWS EC2 Region
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# AWS EC2 Instance Type
variable "aws_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t3.micro"
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# SSH Public Key Path
variable "ssh_public_key_path" {
  description = "Path to the local SSH public key to install on the instance"
  type        = string
  default     = "~/.ssh/cloud1_key.pub"
}