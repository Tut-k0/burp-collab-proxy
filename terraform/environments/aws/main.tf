terraform {
  required_version = ">= 1.0"

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BurpCollaborator"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "burp_collaborator" {
  source = "../../modules/aws-burp-collab"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  instance_type        = var.instance_type
  root_volume_size     = var.root_volume_size
  ssh_public_key       = var.ssh_public_key
  ssh_private_key_path = var.ssh_private_key_path
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
  collaborator_domain  = var.collaborator_domain
  create_route53_zone  = var.create_route53_zone
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
}

# Generate ansible inventory file
resource "local_file" "ansible_inventory" {
  content  = module.burp_collaborator.ansible_inventory
  filename = "${path.module}/../../../ansible/inventory/aws"
}

# Output DNS instructions
resource "local_file" "dns_instructions" {
  content = templatefile("${path.module}/dns-instructions.tpl", {
    domain              = var.collaborator_domain
    public_ip           = module.burp_collaborator.public_ip
    create_route53_zone = var.create_route53_zone
    nameservers         = module.burp_collaborator.route53_nameservers
  })
  filename = "${path.module}/DNS_SETUP.txt"
}