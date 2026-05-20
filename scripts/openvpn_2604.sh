#!/bin/bash

# Bash script for intializing OpenVPN
# set error trap to exit the script immediately on first error.
set -e

DEBIAN_FRONTEND=noninteractive 
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Function to wait for apt lock to be released
wait_for_apt() {
    local max_wait=300  # Maximum wait time in seconds
    local waited=0

    while fuser /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
          /var/cache/apt/archives/lock >/dev/null 2>&1; do
        if [ "$waited" -ge "$max_wait" ]; then
            echo "Timeout waiting for apt lock. Exiting."
            exit 1
        fi
        echo "Waiting for apt lock... ($waited seconds)"
        sleep 5
        waited=$((waited + 5))
    done
}

# install
# apt-get install -y ca-certificates curl unbound openvpn iptables openssl curl ca-certificates tar dnsutils socat

# Log output of installation to a file for reference 
script_log="setup_log_`date +%F`.log"
exec 1>>$script_log
exec 2>&1

export openvpn_user=$(whoami)
pkg="openvpn"

echo "Initializing script..." && echo ""
echo "Updating/Upgrading the packages..."

wait_for_apt
sudo apt update
# sudo apt upgrade -y
wait_for_apt

# Create keyrings directory
echo "Creating keyrings directory => /etc/apt/keyrings"
echo "Downloading OpenVPN GPG key"
sudo curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg -o /etc/apt/keyrings/openvpn-repo-public.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/openvpn-repo-public.asc] https://build.openvpn.net/debian/openvpn/stable resolute main" |sudo tee /etc/apt/sources.list.d/openvpn-aptrepo.list

sudo flock /var/lib/apt/lists/lock -c "apt update"
wait_for_apt

echo "Installing dialog and apt-utils for interactive systems"
sudo apt install -y dialog apt-utils

echo "Installing prerequisites ca-certificates curl"
sudo apt install -y ca-certificates curl unbound

echo "Installing Unbound DNS resolver"
sudo apt install -y unbound

echo "Installing OpenVPN and dependencies"
sudo apt install -y openvpn iptables openssl tar dnsutils socat

# Use before any apt operation
wait_for_apt

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

echo "--------------------------------------------------------"
echo "Installing OpenVPN Access Server..."
echo "Adding client ${openvpn_user} to the configuration!"
echo "--------------------------------------------------------"

# sudo ./openvpn-install.sh --verbose install --dns cloudflare
# set few non-interactive variables for installation
export AUTO_INSTALL=y
export APPROVE_INSTALL=y
sudo ./openvpn-install.sh \
    --verbose install \
    --dns cloudflare \
    --client ubuntu \
    --client-cert-days 36 \
    --server-cert-days 36

if [[ $? -ne 0 ]] ; then
    echo "FAIL: OpenVPN installation failed!"
    exit 1
fi

echo "Checking for availability of OpenVPN as a prerequisite!"
openvpn --version

dpkg -s ${pkg} &> /dev/null
if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    dpkg -s ${pkg}
    echo "--------------------------------------------------------"
else
    echo "--------------------------------------------------------"
    echo "Package ${pkg} is NOT installed. Check log ${script_log} and ~/openvpn-install.log!"
    echo "--------------------------------------------------------"
fi

echo "Open Profile ${openvpn_user}.ovpn created"
ls -l ~/${openvpn_user}.ovpn

echo
echo "OpenVPN Installed & Configured succesfully!"