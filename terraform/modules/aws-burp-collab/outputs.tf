output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.burp_server.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_eip.burp_eip.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.burp_server.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.burp_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.burp_public.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.burp_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_eip.burp_eip.public_ip}"
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.create_route53_zone ? aws_route53_zone.burp_zone[0].zone_id : null
}

output "route53_nameservers" {
  description = "Route53 nameservers for domain delegation"
  value       = var.create_route53_zone ? aws_route53_zone.burp_zone[0].name_servers : null
}

output "ansible_inventory" {
  description = "Ansible inventory content for this host"
  value = <<-EOT
    [aws]
    ${aws_eip.burp_eip.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.ssh_private_key_path}

    [aws:vars]
    ansible_python_interpreter=/usr/bin/python3
  EOT
}