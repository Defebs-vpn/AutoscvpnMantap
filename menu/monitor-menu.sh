#!/bin/bash
# System Monitoring Script
# Author: Defebs-vpn
# Created: 2025-02-09 11:56:14 UTC

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration
source /etc/AutoscvpnMantap/config/variables.conf

show_header() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "              ${GREEN}System Monitoring${NC}                  "
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_resources() {
    CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
    MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    DISK=$(df -h | awk '$NF=="/"{printf "%s", $5}')
    UPTIME=$(uptime -p)
    
    echo -e "${YELLOW}System Resources:${NC}"
    echo -e " CPU Usage    : $CPU"
    echo -e " Memory Usage : $MEMORY"
    echo -e " Disk Usage   : $DISK"
    echo -e " Uptime      : $UPTIME"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_services() {
    echo -e "${YELLOW}Service Status:${NC}"
    systemctl is-active ssh > /dev/null 2>&1 && echo -e " SSH Service  : ${GREEN}Running${NC}" || echo -e " SSH Service  : ${RED}Stopped${NC}"
    systemctl is-active nginx > /dev/null 2>&1 && echo -e " Nginx Service: ${GREEN}Running${NC}" || echo -e " Nginx Service: ${RED}Stopped${NC}"
    systemctl is-active xray > /dev/null 2>&1 && echo -e " Xray Service : ${GREEN}Running${NC}" || echo -e " Xray Service : ${RED}Stopped${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_connections() {
    echo -e "${YELLOW}Current Connections:${NC}"
    echo -e " SSH Users    : $(who | grep -c pts)"
    echo -e " Xray Users   : $(netstat -tnp | grep ESTABLISHED | grep xray | wc -l)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

while true; do
    show_header
    show_resources
    show_services
    show_connections
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e " [1] Refresh Status"
    echo -e " [2] View Process List"
    echo -e " [3] View Network Statistics"
    echo -e " [0] Return to Main Menu"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "Select option [0-3]: " option
    
    case $option in
        1) continue ;;
        2) top ;;
        3) netstat -tulpn ;;
        0) break ;;
        *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
    esac
done

menu