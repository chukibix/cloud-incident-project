// The instance's public IP for SSH
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.k8s.public_ip
}

// Direct link to the backend homepage
output "app_url" {
  description = "URL of the backend / showcase homepage"
  value       = "http://${aws_eip.k8s.public_ip}/"
}

//  RDS connection endpoint used by the backend
output "rds_endpoint" {
  description = "Connection endpoint for the RDS Postgres instance"
  value       = aws_db_instance.main.endpoint
}

output "ssh_command" {
  description = "SSH into the instance (replace the key path if different)"
  value       = "ssh -i ~/cloud-incident-keyy.pem ubuntu@${aws_eip.k8s.public_ip}"
}

// after SSH reach Grafana
output "grafana_tunnel_command" {
  description = "Run this ON the instance, after connecting with ssh_command, and keep this terminal open"
  value       = "sudo kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
}

//SSH command with local port forwarding for Grafana
output "ssh_command_to_get_to_grafana" {
  description = "SSH into the instance with local port forwarding enabled"
  value       = "ssh -i ~/cloud-incident-keyy.pem -L 3000:localhost:3000 ubuntu@${aws_eip.k8s.public_ip}"
}

// Command to fetch the Grafana admin password
output "grafana_password_command" {
  description = "Run in an SSH session to get the Grafana admin password (username: admin)"
  value       = "sudo kubectl get secret monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d; echo"
}