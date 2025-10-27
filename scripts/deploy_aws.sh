#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Burp Collaborator AWS Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check dependencies
for cmd in terraform ansible dig; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Missing required dependency: $cmd${NC}"
        exit 1
    fi
done

# Verify config files exist
if [ ! -f "terraform/environments/aws/terraform.tfvars" ]; then
    echo -e "${RED}ERROR: terraform.tfvars not found${NC}"
    echo "Copy terraform.tfvars.example and configure it first"
    exit 1
fi

if [ ! -f "ansible/group_vars/aws.yml" ]; then
    echo -e "${RED}ERROR: ansible/group_vars/aws.yml not found${NC}"
    exit 1
fi

# Terraform
cd terraform/environments/aws
echo -e "${GREEN}[1/3] Running Terraform...${NC}"
terraform init
terraform plan -out=tfplan

read -p "Apply changes? (y/N) " -r
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "Cancelled" && rm -f tfplan && exit 0

terraform apply tfplan
rm -f tfplan

PUBLIC_IP=$(terraform output -raw public_ip)
echo -e "${GREEN}Infrastructure created! IP: ${BLUE}${PUBLIC_IP}${NC}"

# DNS instructions
if [ -f "DNS_SETUP.txt" ]; then
    echo ""
    cat DNS_SETUP.txt
    echo ""
    read -p "Configure DNS A records and press Enter to continue..."
fi

# Ansible
cd ../../../ansible
echo -e "${GREEN}[2/3] Testing connectivity...${NC}"
if ! ansible aws -i inventory/aws -m ping >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to server${NC}"
    exit 1
fi

echo -e "${GREEN}[3/3] Running Ansible playbook...${NC}"
ansible-playbook -i inventory/aws playbooks/deploy-aws.yml

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "- Configure NS records (see DNS_SETUP.txt)"
echo "- Configure Burp Suite Professional"
echo ""