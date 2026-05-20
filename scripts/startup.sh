#!/bin/bash

# For providing custom root password
# echo 'root:p@s$w0rd' | chpasswd
# echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
# echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config

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

# Log output of installation to a file for reference 
script_log="setup_apache_log_`date +%F`.log"
exec 1>>$script_log
exec 2>&1

wait_for_apt
sudo apt update

wait_for_apt
sudo apt-get -y install apache2

# Start a simple Apache HTTP instance to test
# a custom html page to display
cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>GCP Web Server</title>
    </head>
    <body style="background-color: rgb(255, 250, 240);">
	    <h1><center>Welcome To Terraform IaC!!!</center></h1>
	    <h2><center> GCP Host:</b> $(hostname -f) </center></h2>
    </body>
</html>
EOF

# now start and enable the apache service
sudo systemctl start apache2
sudo systemctl enable apache2

if systemctl is-active --quiet apache2; then
    echo -e "  ${GREEN}→${BLANK} Status: Apache2 Running"
else
    echo -e "  ${YELLOW}→${BLANK} Status: Apache2 Not running"
    sudo systemctl start apache2
fi