#!/bin/bash
# AutoscvpnMantap Xray Menu
# Created: 2025-02-09 13:31:53 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Show Xray status
show_xray_status() {
    echo -e "${COLOR_YELLOW}Xray Status:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Check service status
    if systemctl is-active --quiet xray; then
        echo -e " ${COLOR_GREEN}●${COLOR_NC} Service Status : ${COLOR_GREEN}Running${COLOR_NC}"
    else
        echo -e " ${COLOR_RED}●${COLOR_NC} Service Status : ${COLOR_RED}Stopped${COLOR_NC}"
    fi
    
    # Show version
    XRAY_VER=$(/usr/local/bin/xray version | head -n1 | awk '{print $2}')
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Xray Version  : $XRAY_VER"
    
    # Show running protocols
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Active Protocols:"
    for proto in vless vmess trojan; do
        count=$(grep -c "\"protocol\": \"$proto\"" /etc/AutoscvpnMantap/xray/config.json)
        if [ $count -gt 0 ]; then
            echo -e "   - ${COLOR_GREEN}$proto${COLOR_NC} (Enabled)"
        else
            echo -e "   - ${COLOR_RED}$proto${COLOR_NC} (Disabled)"
        fi
    done
    
    # Show active connections
    active_conn=$(netstat -tnp | grep xray | grep ESTABLISHED | wc -l)
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Active Connections: $active_conn"
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Show Xray menu
show_xray_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "               ${COLOR_GREEN}Xray Menu${COLOR_NC}                        "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    show_xray_status
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Add User"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Delete User"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • List Users"
    echo -e " ${COLOR_GREEN}[4]${COLOR_NC} • Check User Login"
    echo -e " ${COLOR_GREEN}[5]${COLOR_NC} • Renew User"
    echo -e " ${COLOR_GREEN}[6]${COLOR_NC} • Show Config"
    echo -e " ${COLOR_GREEN}[7]${COLOR_NC} • Restart Service"
    echo -e " ${COLOR_GREEN}[8]${COLOR_NC} • Change Port"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main loop
while true; do
    show_xray_menu
    read -p "Select option [0-8]: " option
    
    case $option in
        1) add_xray_user ;;
        2) delete_xray_user ;;
        3) list_xray_users ;;
        4) check_xray_login ;;
        5) renew_xray_user ;;
        6) show_xray_config ;;
        7) 
            systemctl restart xray
            echo -e "${COLOR_GREEN}Xray service restarted${COLOR_NC}"
            sleep 2
            ;;
        8) change_xray_port ;;
        0) break ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 1
            ;;
    esac
done

# Return to main menu
menu