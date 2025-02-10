#!/bin/bash
# AutoscvpnMantap Security Menu
# Created: 2025-02-09 13:22:18 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Function to update firewall rules
update_firewall() {
    echo -e "${COLOR_YELLOW}Updating firewall rules...${COLOR_NC}"
    
    # Reset UFW
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow custom ports
    if [ -f "/etc/AutoscvpnMantap/config/ports.conf" ]; then
        while read -r port; do
            ufw allow $port
        done < "/etc/AutoscvpnMantap/config/ports.conf"
    fi
    
    # Enable UFW
    ufw --force enable
    
    echo -e "${COLOR_GREEN}Firewall rules updated successfully${COLOR_NC}"
    # Log update
    echo "[$CURRENT_DATE UTC] Firewall rules updated by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/security.log
}

# Function to change SSH port
change_ssh_port() {
    echo -e "${COLOR_YELLOW}Change SSH Port${COLOR_NC}"
    read -p "Enter new SSH port: " new_port
    
    # Validate port number
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
        echo -e "${COLOR_RED}Invalid port number${COLOR_NC}"
        return
    fi
    
    # Update SSH config
    sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    
    # Update firewall
    ufw allow $new_port/tcp
    
    # Restart SSH service
    systemctl restart sshd
    
    echo -e "${COLOR_GREEN}SSH port changed to $new_port${COLOR_NC}"
    # Log change
    echo "[$CURRENT_DATE UTC] SSH port changed to $new_port by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/security.log
}

# Function to show security status
show_security_status() {
    echo -e "${COLOR_YELLOW}Security Status:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Check SSH
    ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} SSH Port: $ssh_port"
    
    # Check UFW status
    ufw_status=$(ufw status | grep "Status: " | cut -d' ' -f2)
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Firewall: $ufw_status"
    
    # List open ports
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Open Ports:"
    netstat -tulpn | grep LISTEN | awk '{print $4}' | cut -d: -f2 | sort -n | uniq | while read port; do
        echo -e "   - Port $port"
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Show security menu
show_security_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Security Management${COLOR_NC}                  "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    show_security_status
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Update Firewall Rules"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Change SSH Port"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • View Security Logs"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# View security logs
view_security_logs() {
    echo -e "${COLOR_YELLOW}Security Logs:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    if [ -f "/etc/AutoscvpnMantap/logs/security.log" ]; then
        tail -n 50 /etc/AutoscvpnMantap/logs/security.log
    else
        echo -e "${COLOR_YELLOW}No security logs found${COLOR_NC}"
    fi
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Press enter to continue..."
}

# Main loop
while true; do
    show_security_menu
    read -p "Select option [0-3]: " option
    
    case $option in
        1) update_firewall ;;
        2) change_ssh_port ;;
        3) view_security_logs ;;
        0) break ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 1
            ;;
    esac
done

# Return to main menu
menu