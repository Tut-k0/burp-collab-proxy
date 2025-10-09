terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "burp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "burp_igw" {
  vpc_id = aws_vpc.burp_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "burp_public" {
  vpc_id                  = aws_vpc.burp_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table
resource "aws_route_table" "burp_public" {
  vpc_id = aws_vpc.burp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.burp_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "burp_public" {
  subnet_id      = aws_subnet.burp_public.id
  route_table_id = aws_route_table.burp_public.id
}

# Security Group
resource "aws_security_group" "burp_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Burp Collaborator"
  vpc_id      = aws_vpc.burp_vpc.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS TCP
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS UDP
  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SMTP
  ingress {
    description = "SMTP"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SMTPS
  ingress {
    description = "SMTPS"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Elastic IP
resource "aws_eip" "burp_eip" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.burp_igw]
}

# SSH Key Pair
resource "aws_key_pair" "burp_key" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name        = "${var.project_name}-key"
    Project     = var.project_name
    Environment = var.environment
  }
}

# EC2 Instance
resource "aws_instance" "burp_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.burp_public.id
  key_name      = aws_key_pair.burp_key.key_name

  vpc_security_group_ids = [aws_security_group.burp_sg.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    hostname = var.collaborator_domain
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-server"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Associate EIP with instance
resource "aws_eip_association" "burp_eip_assoc" {
  instance_id   = aws_instance.burp_server.id
  allocation_id = aws_eip.burp_eip.id
}

# Route53 Hosted Zone (if managing DNS in AWS)
resource "aws_route53_zone" "burp_zone" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.collaborator_domain

  tags = {
    Name        = "${var.project_name}-zone"
    Project     = var.project_name
    Environment = var.environment
  }
}

# A Records for collaborator domain
resource "aws_route53_record" "burp_a" {
  count   = var.create_route53_zone ? 1 : 0
  zone_id = aws_route53_zone.burp_zone[0].zone_id
  name    = var.collaborator_domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.burp_eip.public_ip]
}

# Wildcard A record
resource "aws_route53_record" "burp_wildcard" {
  count   = var.create_route53_zone ? 1 : 0
  zone_id = aws_route53_zone.burp_zone[0].zone_id
  name    = "*.${var.collaborator_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.burp_eip.public_ip]
}

# NS record for subdomain delegation
resource "aws_route53_record" "burp_ns" {
  count   = var.create_route53_zone ? 1 : 0
  zone_id = aws_route53_zone.burp_zone[0].zone_id
  name    = var.collaborator_domain
  type    = "NS"
  ttl     = 300
  records = [
    "ns1.${var.collaborator_domain}"
  ]
}

# NS1 A record
resource "aws_route53_record" "burp_ns1" {
  count   = var.create_route53_zone ? 1 : 0
  zone_id = aws_route53_zone.burp_zone[0].zone_id
  name    = "ns1.${var.collaborator_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.burp_eip.public_ip]
}