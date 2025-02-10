#!/bin/bash
# AutoscvpnMantap Status Menu
# Created: 2025-02-09 12:00:29 UTC
# Author: Defebs-vpn

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Current date/time in UTC
CURRENT_DATE=$(date -u +"%Y-%m-%d %H:%M:%S")
CURRENT_USER="Defebs-vpn"

show_status_header() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                ${GREEN}System Status${NC}                   "
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${BLUE}➣${NC} Date & Time : $CURRENT_DATE UTC"
    echo -e " ${BLUE}➣${NC} User        : $CURRENT_USER"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_service_status() {
    echo -e "${YELLOW}Service Status:${NC}"
    # SSH Status
    if systemctl is-active ssh >/dev/null 2>&1; then
        echo -e " ${GREEN}●${NC} SSH Service       : ${GREEN}Running${NC}"
    else
        echo -e " ${RED}●${NC} SSH Service       : ${RED}Stopped${NC}"
    fi
    
    # Nginx Status
    if systemctl is-active nginx >/dev/null 2>&1; then
        echo -e " ${GREEN}●${NC} Nginx Service     : ${GREEN}Running${NC}"
    else
        echo -e " ${RED}●${NC} Nginx Service     : ${RED}Stopped${NC}"
    fi
    
    # Xray Status
    if systemctl is-active xray >/dev/null 2>&1; then
        echo -e " ${GREEN}●${NC} Xray Service      : ${GREEN}Running${NC}"
    else
        echo -e " ${RED}●${NC} Xray Service      : ${RED}Stopped${NC}"
    fi
}

show_port_status() {
    echo -e "\n${YELLOW}Port Status:${NC}"
    # Check common ports
    local ports=(22 80 443 8443)
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e " ${GREEN}●${NC} Port $port         : ${GREEN}Open${NC}"
        else
            echo -e " ${RED}●${NC} Port $port         : ${RED}Closed${NC}"
        fi
    done
}

show_system_load() {
    echo -e "\n${YELLOW}System Load:${NC}"
    local cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local mem_used=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    local disk_used=$(df -h / | awk 'NR==2{print $5}')
    
    echo -e " ${BLUE}➣${NC} CPU Usage       : $cpu_load%"
    echo -e " ${BLUE}➣${NC} Memory Usage    : $mem_used"
    echo -e " ${BLUE}➣${NC} Disk Usage      : $disk_used"
}

show_user_status() {
    echo -e "\n${YELLOW}Active Users:${NC}"
    echo -e " ${BLUE}➣${NC} SSH Users       : $(who | grep -c pts)"
    echo -e " ${BLUE}➣${NC} Xray Users      : $(netstat -tnp | grep -c xray)"
}

show_status_menu() {
    show_status_header
    show_service_status
    show_port_status
    show_system_load
    show_user_status
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e " [1] Restart All Services"
    echo -e " [2] View System Logs"
    echo -e " [3] Network Statistics"
    echo -e " [4] Check SSL Certificate"
    echo -e " [0] Back to Main Menu"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

restart_services() {
    echo -e "${YELLOW}Restarting services...${NC}"
    systemctl restart ssh
    systemctl restart nginx
    systemctl restart xray
    echo -e "${GREEN}Services restarted successfully!${NC}"
    sleep 2
}

view_logs() {
    echo -e "${YELLOW}Select log to view:${NC}"
    echo -e "1) System Log"
    echo -e "2) SSH Log"
    echo -e "3) Nginx Error Log"
    echo -e "4) Xray Access Log"
    read -p "Select log [1-4]: " log_choice
    
    case $log_choice in
        1) tail -n 100 /etc/AutoscvpnMantap/logs/system.log ;;
        2) tail -n 100 /var/log/auth.log ;;
        3) tail -n 100 /var/log/nginx/error.log ;;
        4) tail -n 100 /var/log/xray/access.log ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
    read -p "Press enter to continue..."
}

check_ssl() {
    echo -e "${YELLOW}Checking SSL Certificate...${NC}"
    certbot certificates
    read -p "Press enter to continue..."
}

# Main loop
while true; do
    show_status_menu
    read -p "Select option [0-4]: " choice
    
    case $choice in
        1) restart_services ;;
        2) view_logs ;;
        3) netstat -tulpn ; read -p "Press enter to continue..." ;;
        4) check_ssl ;;
        0) break ;;
        *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
    esac
done