variable "project_name" {
  description = "Project name"
  type        = string
  default     = "burp-collaborator"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}

variable "ssh_private_key_path" {
  description = "SSH private key location to use for accessing EC2 instance"
  type = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "collaborator_domain" {
  description = "Domain for Burp Collaborator"
  type        = string
}

variable "create_route53_zone" {
  description = "Create Route53 hosted zone"
  type        = bool
  default     = false
}