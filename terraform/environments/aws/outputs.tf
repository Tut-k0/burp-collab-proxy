output "instance_id" {
  description = "EC2 instance ID"
  value       = module.burp_collaborator.instance_id
}

output "public_ip" {
  description = "Public IP address"
  value       = module.burp_collaborator.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = module.burp_collaborator.private_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = module.burp_collaborator.ssh_command
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.burp_collaborator.vpc_id
}

output "route53_zone_id" {
  description = "Route53 zone ID"
  value       = module.burp_collaborator.route53_zone_id
}

output "route53_nameservers" {
  description = "Route53 nameservers"
  value       = module.burp_collaborator.route53_nameservers
}

output "next_steps" {
  description = "Next steps"
  value = <<-EOT

    ========================================
    Burp Collaborator AWS Infrastructure Created!
    ========================================

    Instance Details:
      Instance ID: ${module.burp_collaborator.instance_id}
      Public IP:   ${module.burp_collaborator.public_ip}
      SSH:         ${module.burp_collaborator.ssh_command}

    DNS Setup:
      ${var.create_route53_zone ? "Route53 zone created. Check DNS_SETUP.txt for nameserver delegation instructions." : "No Route53 zone created. Set up DNS manually - see DNS_SETUP.txt"}

    Next Steps:
      1. Review DNS_SETUP.txt and configure your domain registrar
      2. Wait for DNS propagation (can take up to 48hrs, usually much faster)
      3. Run ansible playbook:
         cd ../../../ansible
         ansible-playbook -i inventory/aws playbooks/deploy-aws.yml
      4. Monitor deployment:
         ssh ubuntu@${module.burp_collaborator.public_ip}
         sudo journalctl -u burp-collaborator -f

    Ansible inventory generated at: ansible/inventory/aws

  EOT
}