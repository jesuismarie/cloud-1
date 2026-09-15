# This file contains the output values for the Terraform configuration.

# Instance ID of EC2 instance
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cloud-1.id
}

# Private IP address of EC2 instance
output "private_ip" {
  description = "EC2 instance private IP address"
  value       = aws_instance.cloud-1.private_ip
}

# Public IP address of EC2 instance
output "public_ip" {
  description = "EC2 instance public IP address"
  value       = aws_instance.cloud-1.public_ip
}

# SSH command to connect to the EC2 instance
output "ssh_command" {
  description = "The SSH command to connect to the EC2 instance"
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${aws_instance.cloud-1.public_ip}"
  sensitive   = true
}
