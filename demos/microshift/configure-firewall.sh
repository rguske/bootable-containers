#!/bin/bash
# Configure firewall for MicroShift

set -euo pipefail

echo "Configuring firewall for MicroShift..."

# Required ports for MicroShift
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=169.254.169.1
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=6443/tcp
firewall-cmd --permanent --zone=public --add-port=5353/udp
firewall-cmd --permanent --zone=public --add-port=30000-32767/tcp
firewall-cmd --permanent --zone=public --add-port=30000-32767/udp

firewall-cmd --reload

echo "Firewall configuration complete."
