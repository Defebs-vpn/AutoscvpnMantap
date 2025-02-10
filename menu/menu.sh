#!/bin/bash
# AutoscvpnMantap Menu System
# Author: Defebs-vpn
# Created: 2025-02-09 11:56:14 UTC

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load configuration
source /etc/AutoscvpnMantap/config/variables.conf

# System Information
MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
DISK=$(df -h | awk '$NF=="/"{printf "%s", $5}')
CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
UPTIME=$(uptime -p | cut -d " " -f 2-)

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "               ${GREEN}AutoscvpnMantap Menu${NC}               "
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " ${YELLOW}System Information:${NC}"
echo -e " ${BLUE}➣${NC} CPU Usage    : $CPU"
echo -e " ${BLUE}➣${NC} Memory Usage : $MEMORY"
echo -e " ${BLUE}➣${NC} Disk Usage   : $DISK"
echo -e " ${BLUE}➣${NC} Uptime      : $UPTIME"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}[1]${NC} • SSH & OpenVPN Menu"
echo -e "  ${GREEN}[2]${NC} • X-ray Menu (VLESS/VMESS/TROJAN)"
echo -e "  ${GREEN}[3]${NC} • Server Settings"
echo -e "  ${GREEN}[4]${NC} • Security & Firewall"
echo -e "  ${GREEN}[5]${NC} • System Monitor"
echo -e "  ${GREEN}[6]${NC} • Backup & Restore"
echo -e "  ${GREEN}[7]${NC} • Certificate Management"
echo -e "  ${GREEN}[0]${NC} • Exit Menu"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " ${YELLOW}Server Information:${NC}"
echo -e " ${BLUE}➣${NC} Domain      : $DOMAIN"
echo -e " ${BLUE}➣${NC} IP Address  : $IPV4"
echo -e " ${BLUE}➣${NC} Date & Time : $(date)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
read -p "Select menu [1-7 or 0]: " menu_choice

case $menu_choice in
    1) ssh-menu ;;
    2) xray-menu ;;
    3) settings-menu ;;
    4) security-menu ;;
    5) monitor-menu ;;
    6) backup-menu ;;
    7) cert-menu ;;
    0) clear ; exit 0 ;;
    *) echo -e "${RED}Invalid Choice!${NC}" ; sleep 1 ; menu ;;
esac