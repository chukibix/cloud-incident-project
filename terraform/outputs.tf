// The instance's public IP — use this directly for API calls or SSH
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.k8s.public_ip
}

// Direct link to the backend homepage/showcase, ready to open right after apply
output "app_url" {
  description = "URL of the backend / showcase homepage"
  value       = "http://${aws_eip.k8s.public_ip}/"
}

// The RDS connection endpoint (host:port) — used by the backend, not usually needed manually
output "rds_endpoint" {
  description = "Connection endpoint for the RDS Postgres instance"
  value       = aws_db_instance.main.endpoint
}

output "ssh_command" {
  description = "SSH into the instance (replace the key path if different)"
  value       = "ssh -i ~/cloud-incident-keyy.pem ubuntu@${aws_eip.k8s.public_ip}"
}

// The exact command to run ON the instance (after SSH-ing in) to reach Grafana
output "grafana_tunnel_command" {
  description = "Run this ON the instance, after connecting with ssh_command, and keep this terminal open"
  value       = "sudo kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
}

// Ready-to-paste SSH command with local port forwarding for Grafana
output "ssh_command_to_get_to_grafana" {
  description = "SSH into the instance with local port forwarding enabled"
  value       = "ssh -i ~/cloud-incident-keyy.pem -L 3000:localhost:3000 ubuntu@${aws_eip.k8s.public_ip}"
}

// Command to fetch the Grafana admin password — needs its own SSH session (not the tunneled one)
output "grafana_password_command" {
  description = "Run in an SSH session to get the Grafana admin password (username: admin)"
  value       = "sudo kubectl get secret monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d; echo"
}