#!/bin/bash

# Update package list and install pip if not already installed
sudo apt-get update
sudo apt-get install -y python3-pip

# Install the required Python modules
pip3 install azure-identity azure-mgmt-resource azure-mgmt-network python-docx

# Verify the installation
echo "Installed Python packages:"
pip3 list | grep -E 'azure-identity|azure-mgmt-resource|azure-mgmt-network|python-docx'

echo "All required Python modules have been installed successfully."