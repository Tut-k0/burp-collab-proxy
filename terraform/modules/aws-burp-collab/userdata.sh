#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}

# Install Python for Ansible
apt-get install -y python3 python3-pip

# Disable unnecessary services
systemctl disable snapd --now || true

# Configure unattended upgrades for security
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo "User data script completed" > /var/log/userdata.log