#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}DESTROY AWS INFRASTRUCTURE${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Check if terraform state exists
if [ ! -f "terraform/environments/aws/terraform.tfstate" ]; then
    echo -e "${YELLOW}No terraform state found. Nothing to destroy.${NC}"
    exit 0
fi

cd terraform/environments/aws

# Get current info
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")
DOMAIN=$(grep "collaborator_domain:" ../../ansible/group_vars/aws.yml 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "N/A")

echo -e "${YELLOW}Current deployment:${NC}"
echo "  IP: ${PUBLIC_IP}"
echo "  Domain: ${DOMAIN}"
echo ""

echo -e "${RED}This will destroy all AWS resources!${NC}"
echo -e "${RED}All data will be permanently lost!${NC}"
echo ""

# Confirmation
read -p "Type 'destroy' to confirm: " CONFIRM1
[ "$CONFIRM1" != "destroy" ] && echo "Cancelled" && exit 0

# Destroy
echo ""
echo -e "${RED}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

# Cleanup
echo ""
echo -e "${GREEN}Cleanup local files...${NC}"
rm -f ../../../ansible/inventory/aws
rm -f deployment-info.txt
rm -f DNS_SETUP.txt
rm -f tfplan

echo ""
echo -e "${GREEN}Destruction complete!${NC}"
echo ""
echo -e "${YELLOW}Manual cleanup:${NC}"
echo "- Remove DNS records at your registrar"
echo "- Clean up any local SSH keys if needed"
echo ""