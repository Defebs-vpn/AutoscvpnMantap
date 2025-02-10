#!/bin/bash
# AutoscvpnMantap Xray Management Functions
# Created: 2025-02-09 14:11:19 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Check Xray user login status
check_xray_login() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Xray Login Monitor${COLOR_NC}                  "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    echo -e "${COLOR_YELLOW}Current Time: $CURRENT_DATE UTC${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Get active connections
    echo -e "${COLOR_YELLOW}Active Connections:${COLOR_NC}"
    printf "%-4s %-20s %-15s %-20s\n" "No" "Username" "Protocol" "Connected Since"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    number=1
    # Check each protocol
    for proto in vless vmess trojan; do
        connections=$(netstat -tnp | grep xray | grep ESTABLISHED)
        if [ ! -z "$connections" ]; then
            echo "$connections" | while read line; do
                ip=$(echo $line | awk '{print $5}' | cut -d: -f1)
                port=$(echo $line | awk '{print $5}' | cut -d: -f2)
                connected_time=$(date -d @$(stat -c %Y /proc/$(echo $line | awk '{print $7}' | cut -d/ -f1)) '+%Y-%m-%d %H:%M:%S')
                
                # Get username from connection
                username=$(grep -l "$ip" /etc/AutoscvpnMantap/users/*/info.json | cut -d/ -f5)
                
                if [ ! -z "$username" ]; then
                    printf "%-4s %-20s %-15s %-20s\n" "$number" "$username" "$proto" "$connected_time"
                    ((number++))
                fi
            done
        fi
    done
    
    if [ $number -eq 1 ]; then
        echo -e "${COLOR_YELLOW}No active connections${COLOR_NC}"
    fi
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Press enter to continue..."
}

# Renew Xray user
renew_xray_user() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Renew Xray User${COLOR_NC}                   "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # List existing users
    echo -e "${COLOR_YELLOW}Current users:${COLOR_NC}"
    printf "%-4s %-20s %-20s %-10s\n" "No" "Username" "Expired" "Status"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    number=1
    for user in /etc/AutoscvpnMantap/users/*/info.json; do
        if [ -f "$user" ]; then
            username=$(jq -r '.username' "$user")
            expired=$(jq -r '.expired' "$user")
            
            if [[ $(date -d "$expired" +%s) < $(date +%s) ]]; then
                status="${COLOR_RED}Expired${COLOR_NC}"
            else
                status="${COLOR_GREEN}Active${COLOR_NC}"
            fi
            
            printf "%-4s %-20s %-20s %-10s\n" "$number" "$username" "$expired" "$status"
            ((number++))
        fi
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Select user number to renew (0 to cancel): " user_number
    
    if [ "$user_number" = "0" ]; then
        return
    fi
    
    username=$(ls -1 /etc/AutoscvpnMantap/users/ | sed -n "${user_number}p")
    
    if [ -z "$username" ]; then
        echo -e "${COLOR_RED}Invalid selection${COLOR_NC}"
        sleep 2
        return
    fi
    
    read -p "Enter number of days to add: " days
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${COLOR_RED}Invalid number of days${COLOR_NC}"
        sleep 2
        return
    fi
    
    # Calculate new expiry date
    current_exp=$(jq -r '.expired' "/etc/AutoscvpnMantap/users/$username/info.json")
    new_exp=$(date -d "$current_exp +$days days" +"%Y-%m-%d")
    
    # Update user info
    jq --arg exp "$new_exp" '.expired = $exp' "/etc/AutoscvpnMantap/users/$username/info.json" > "/etc/AutoscvpnMantap/users/$username/info.json.tmp"
    mv "/etc/AutoscvpnMantap/users/$username/info.json.tmp" "/etc/AutoscvpnMantap/users/$username/info.json"
    
    # Update configurations
    for proto in vless vmess trojan; do
        if [ -f "/etc/AutoscvpnMantap/users/$username/$proto.txt" ]; then
            sed -i "s/Expired: .*/Expired: $new_exp/" "/etc/AutoscvpnMantap/users/$username/$proto.txt"
        fi
    done
    
    echo -e "${COLOR_GREEN}User $username renewed successfully${COLOR_NC}"
    echo -e "${COLOR_YELLOW}New expiration date: $new_exp${COLOR_NC}"
    
    # Log renewal
    echo "[$CURRENT_DATE UTC] Renewed Xray user: $username (new exp: $new_exp) by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/xray.log
    
    sleep 2
}

# Show Xray configuration
show_xray_config() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Xray Configuration${COLOR_NC}                  "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    echo -e "${COLOR_YELLOW}Current Configuration:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Show simplified configuration
    for proto in vless vmess trojan; do
        echo -e "${COLOR_GREEN}$proto Configuration:${COLOR_NC}"
        port=$(jq -r ".inbounds[] | select(.protocol == \"$proto\") | .port" /etc/AutoscvpnMantap/xray/config.json)
        path=$(jq -r ".inbounds[] | select(.protocol == \"$proto\") | .streamSettings.wsSettings.path" /etc/AutoscvpnMantap/xray/config.json)
        
        echo -e " ${COLOR_BLUE}➣${COLOR_NC} Port: $port"
        echo -e " ${COLOR_BLUE}➣${COLOR_NC} Path: $path"
        echo -e " ${COLOR_BLUE}➣${COLOR_NC} Network: ws"
        echo -e " ${COLOR_BLUE}➣${COLOR_NC} Security: tls"
        echo ""
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Options:${COLOR_NC}"
    echo -e "1) Show full configuration"
    echo -e "2) Edit configuration"
    echo -e "0) Back"
    
    read -p "Select option: " option
    
    case $option in
        1)
            echo -e "${COLOR_YELLOW}Full Configuration:${COLOR_NC}"
            cat /etc/AutoscvpnMantap/xray/config.json | jq
            ;;
        2)
            nano /etc/AutoscvpnMantap/xray/config.json
            systemctl restart xray
            ;;
        0)
            return
            ;;
        *)
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 2
            ;;
    esac
    
    read -p "Press enter to continue..."
}

# Change Xray port
change_xray_port() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Change Xray Port${COLOR_NC}                    "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Show current ports
    echo -e "${COLOR_YELLOW}Current Ports:${COLOR_NC}"
    for proto in vless vmess trojan; do
        port=$(jq -r ".inbounds[] | select(.protocol == \"$proto\") | .port" /etc/AutoscvpnMantap/xray/config.json)
        echo -e " ${COLOR_BLUE}➣${COLOR_NC} $proto: $port"
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "Select protocol to change port:"
    echo -e "1) VLESS"
    echo -e "2) VMESS"
    echo -e "3) TROJAN"
    echo -e "0) Back"
    
    read -p "Select option: " option
    
    case $option in
        [1-3])
            proto_list=("vless" "vmess" "trojan")
            proto=${proto_list[$((option-1))]}
            
            read -p "Enter new port for $proto: " new_port
            
            if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
                echo -e "${COLOR_RED}Invalid port number${COLOR_NC}"
                sleep 2
                return
            fi
            
            # Update configuration
            jq --arg port "$new_port" \
               ".inbounds[] | select(.protocol == \"$proto\") .port = ($port)" \
               /etc/AutoscvpnMantap/xray/config.json > /etc/AutoscvpnMantap/xray/config.json.tmp
            
            mv /etc/AutoscvpnMantap/xray/config.json.tmp /etc/AutoscvpnMantap/xray/config.json
            
            # Update firewall
            ufw allow $new_port
            
            # Restart Xray
            systemctl restart xray
            
            echo -e "${COLOR_GREEN}Port changed successfully${COLOR_NC}"
            # Log port change
            echo "[$CURRENT_DATE UTC] Changed $proto port to $new_port by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/xray.log
            ;;
        0)
            return
            ;;
        *)
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 2
            ;;
    esac
}

# Export functions
export -f check_xray_login
export -f renew_xray_user
export -f show_xray_config
export -f change_xray_port