#!/bin/bash
# AutoscvpnMantap Port Check Utility
# Created: 2025-02-09 14:40:55 UTC
# Author: Defebs-vpn

# Source current info and configs
source /etc/AutoscvpnMantap/menu/current-info.sh
source /etc/AutoscvpnMantap/config/port.conf

# Function to check if port is open
check_port() {
    local port=$1
    local service=$2
    if netstat -tuln | grep -q ":$port "; then
        echo -e " ${COLOR_GREEN}[OPEN]${COLOR_NC} $service (Port $port)"
    else
        echo -e " ${COLOR_RED}[CLOSED]${COLOR_NC} $service (Port $port)"
    fi
}

# Function to check all configured ports
check_all_ports() {
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Port Status Check${COLOR_NC}                 "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    echo -e "${COLOR_YELLOW}SSH Ports:${COLOR_NC}"
    check_port $SSH_PORT1 "SSH"
    check_port $SSH_PORT2 "SSH Alternative"
    check_port $SSH_WS_PORT "SSH WebSocket"
    check_port $SSH_WSS_PORT "SSH WebSocket SSL"
    
    echo -e "\n${COLOR_YELLOW}Dropbear Ports:${COLOR_NC}"
    check_port $DROPBEAR_PORT1 "Dropbear"
    check_port $DROPBEAR_PORT2 "Dropbear Alternative"
    
    echo -e "\n${COLOR_YELLOW}Stunnel Ports:${COLOR_NC}"
    check_port $STUNNEL_PORT1 "Stunnel"
    check_port $STUNNEL_PORT2 "Stunnel Alternative"
    
    echo -e "\n${COLOR_YELLOW}Xray Ports:${COLOR_NC}"
    check_port $XRAY_VLESS_PORT "VLESS"
    check_port $XRAY_VMESS_PORT "VMESS"
    check_port $XRAY_TROJAN_PORT "TROJAN"
    
    echo -e "\n${COLOR_YELLOW}WebSocket Ports:${COLOR_NC}"
    check_port $VLESS_WS_PORT "VLESS WebSocket"
    check_port $VMESS_WS_PORT "VMESS WebSocket"
    check_port $TROJAN_WS_PORT "TROJAN WebSocket"
    
    echo -e "\n${COLOR_YELLOW}Panel & Web Ports:${COLOR_NC}"
    check_port $PANEL_PORT "Control Panel"
    check_port $WEBSERVER_PORT "Web Server"
    check_port $WEBSERVER_SSL_PORT "Web Server SSL"
}

# Function to check specific port
check_specific_port() {
    local port=$1
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Port $port Check${COLOR_NC}                  "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    if netstat -tuln | grep -q ":$port "; then
        echo -e " ${COLOR_GREEN}[OPEN]${COLOR_NC} Port $port is open"
        echo -e " Service: $(lsof -i :$port | grep LISTEN | awk '{print $1}' | uniq)"
        echo -e " Process ID: $(lsof -i :$port | grep LISTEN | awk '{print $2}' | uniq)"
    else
        echo -e " ${COLOR_RED}[CLOSED]${COLOR_NC} Port $port is closed"
    fi
}

# Main menu
show_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Port Check Menu${COLOR_NC}                   "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Check All Ports"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Check Specific Port"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main function
main() {
    while true; do
        show_menu
        read -p "Select option [0-2]: " option
        
        case $option in
            1)
                clear
                check_all_ports
                echo -e "\n${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
                read -p "Press enter to continue..."
                ;;
            2)
                read -p "Enter port number to check: " port
                if [[ "$port" =~ ^[0-9]+$ ]]; then
                    clear
                    check_specific_port $port
                    echo -e "\n${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
                    read -p "Press enter to continue..."
                else
                    echo -e "${COLOR_RED}Invalid port number${COLOR_NC}"
                    sleep 2
                fi
                ;;
            0)
                break
                ;;
            *)
                echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
                sleep 2
                ;;
        esac
    done
}

# Run main function
main