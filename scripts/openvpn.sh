#!/bin/bash

# Bash script for intializing OpenVPN

# Set error trap to exit the script immediately on first error.
set -e 

# Log output of installation to a file for reference 
exec >> /tmp/setup_script.log 2>&1

export openvpn_user=$(whoami)

echo "Initializing script..." && echo ""
echo "Updating packages..."
sudo apt update -y && echo ""
echo "Setting FQDN  & Public IP" && echo ""
FQDN=$(hostname -s)
PUB_IP=$(curl ifconfig.me && echo "")

echo "$FQDN" && echo ""
echo "$PUB_IP" && echo ""
echo "Download openvpn installation script" && echo ""
# Check Agristan's repo for full details on installation script
# https://github.com/angristan/openvpn-install

curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

echo "Installing OpenVPN Access Server..."
sudo ./openvpn-install.sh --verbose install \
  --dns cloudflare \
  --client ubuntu \
  --client-cert-days 36


echo "Open Profile ${openvpn_user}.ovpn created"
ls -l ~/${openvpn_user}.ovpn

echo
echo "OpenVPN Installed Succesfully!"
