#!/bin/bash
# AutoscvpnMantap Current Info
# Created: 2025-02-09 14:22:27 UTC
# Author: Defebs-vpn

# Current UTC timestamp and user info
export CURRENT_DATE="2025-02-09 14:22:27"
export CURRENT_USER="Defebs-vpn"
export INSTALL_DATE="2025-02-09 14:22:27"

# Colors for formatting
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_CYAN='\033[0;36m'
export COLOR_NC='\033[0m'
export COLOR_BOLD='\e[1m'

# System information
export SERVER_IP=$(curl -s ipv4.icanhazip.com)
export HOSTNAME=$(hostname)
export OS_NAME=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
export KERNEL_VERSION=$(uname -r)

# Function to show system information
show_system_info() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}System Information${COLOR_NC}                "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_YELLOW}Current Time  :${COLOR_NC} $CURRENT_DATE UTC"
    echo -e " ${COLOR_YELLOW}Current User  :${COLOR_NC} $CURRENT_USER"
    echo -e " ${COLOR_YELLOW}Server IP     :${COLOR_NC} $SERVER_IP"
    echo -e " ${COLOR_YELLOW}Hostname      :${COLOR_NC} $HOSTNAME"
    echo -e " ${COLOR_YELLOW}OS Version    :${COLOR_NC} $OS_NAME"
    echo -e " ${COLOR_YELLOW}Kernel Ver    :${COLOR_NC} $KERNEL_VERSION"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Export the function
export -f show_system_info