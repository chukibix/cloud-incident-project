// The instance's public IP 
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.k8s.public_ip
}

// The RDS connection endpoint
output "rds_endpoint" {
  description = "Connection endpoint for the RDS Postgres instance"
  value       = aws_db_instance.main.endpoint
}