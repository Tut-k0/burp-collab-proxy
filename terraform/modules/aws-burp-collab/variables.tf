variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "burp-collaborator"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
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
  description = "Domain name for Burp Collaborator"
  type        = string
}

variable "create_route53_zone" {
  description = "Whether to create Route53 hosted zone"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}