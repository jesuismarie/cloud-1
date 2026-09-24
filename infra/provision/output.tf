# This file contains the output values for the Terraform configuration.

# Instance IDs of all EC2 instances
output "instance_id" {
  description = "The IDs of the EC2 instances"
  value       = aws_instance.cloud-1[*].id
}

# Private IP addresses of all EC2 instances
output "private_ip" {
  description = "The private IP addresses of the EC2 instances"
  value       = aws_instance.cloud-1[*].private_ip
  sensitive   = true
}

# Public IP addresses of all EC2 instances
output "public_ip" {
  description = "The public IP addresses of the EC2 instances"
  value       = aws_instance.cloud-1[*].public_ip
}

# SSH commands to connect to each EC2 instance
output "ssh_command" {
  description = "The SSH commands to connect to each EC2 instance"
  value       = [for ip in aws_instance.cloud-1[*].public_ip : "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${ip}"]
  sensitive   = true
}
