#!/bin/bash
# AutoscvpnMantap Main Menu
# Created: 2025-02-09 13:16:16 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Main Menu Header
show_main_header() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}AutoscvpnMantap Panel${COLOR_NC}              "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    show_system_info
}

# Show active connections
show_active_connections() {
    local ssh_users=$(who | grep -c pts)
    local xray_users=$(netstat -tnp | grep -c xray)
    local total_users=$((ssh_users + xray_users))
    
    echo -e "${COLOR_YELLOW}Active Connections:${COLOR_NC}"
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} SSH Users    : $ssh_users"
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Xray Users   : $xray_users"
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Total Users  : $total_users"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main Menu Options
show_main_menu() {
    echo -e "${COLOR_YELLOW}Main Menu:${COLOR_NC}"
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • SSH & OpenVPN Menu"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Xray Menu (VLESS/VMESS/TROJAN)"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • Server Settings"
    echo -e " ${COLOR_GREEN}[4]${COLOR_NC} • Security & Firewall"
    echo -e " ${COLOR_GREEN}[5]${COLOR_NC} • System Monitor"
    echo -e " ${COLOR_GREEN}[6]${COLOR_NC} • Backup & Restore"
    echo -e " ${COLOR_GREEN}[7]${COLOR_NC} • User Management"
    echo -e " ${COLOR_GREEN}[8]${COLOR_NC} • Update Script"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Exit Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main Menu Loop
while true; do
    show_main_header
    show_active_connections
    show_main_menu
    
    read -p "Select menu [0-8]: " menu_option
    
    case $menu_option in
        1) ssh-menu ;;
        2) xray-menu ;;
        3) settings-menu ;;
        4) security-menu ;;
        5) monitor-menu ;;
        6) backup-menu ;;
        7) user-menu ;;
        8) 
            echo -e "${COLOR_YELLOW}Checking for updates...${COLOR_NC}"
            # Add update logic here
            sleep 2
            ;;
        0) 
            clear
            echo -e "${COLOR_GREEN}Thanks for using AutoscvpnMantap${COLOR_NC}"
            exit 0
            ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 1
            ;;
    esac
done