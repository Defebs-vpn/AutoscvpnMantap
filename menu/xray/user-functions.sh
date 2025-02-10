#!/bin/bash
# AutoscvpnMantap Xray User Management Functions
# Created: 2025-02-09 14:01:33 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Add Xray user
add_xray_user() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Add Xray User${COLOR_NC}                     "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Get user input
    read -p "Username: " username
    read -p "Duration (days): " duration
    
    # Generate UUID
    uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Calculate expiry date
    exp_date=$(date -d "+${duration} days" +"%Y-%m-%d")
    
    # Add user to configuration
    for proto in vless vmess trojan; do
        # Backup config
        cp /etc/AutoscvpnMantap/xray/config.json /etc/AutoscvpnMantap/xray/config.json.bak
        
        # Add user to protocol
        jq --arg user "$username" \
           --arg uuid "$uuid" \
           --arg exp "$exp_date" \
           '.inbounds[] | select(.protocol == "'$proto'") .settings.clients += [{
               id: $uuid,
               email: $user,
               exp: $exp
           }]' /etc/AutoscvpnMantap/xray/config.json > /etc/AutoscvpnMantap/xray/config.json.tmp
        
        mv /etc/AutoscvpnMantap/xray/config.json.tmp /etc/AutoscvpnMantap/xray/config.json
    done
    
    # Create user config directory
    mkdir -p /etc/AutoscvpnMantap/users/$username
    
    # Save user info
    cat > /etc/AutoscvpnMantap/users/$username/info.json << EOF
{
    "username": "$username",
    "uuid": "$uuid",
    "created": "$CURRENT_DATE",
    "expired": "$exp_date",
    "created_by": "$CURRENT_USER"
}
EOF
    
    # Generate client configurations
    domain=$(cat /etc/AutoscvpnMantap/config/domain.conf)
    
    # VLESS Configuration
    cat > /etc/AutoscvpnMantap/users/$username/vless.txt << EOF
====== VLESS CONFIGURATION ======
Remarks: ${domain}_VLESS_${username}
Domain: ${domain}
Port: 443
UUID: ${uuid}
Path: /vless
Network: ws
TLS: tls
Created: $CURRENT_DATE
Expired: $exp_date

URL: vless://${uuid}@${domain}:443?path=%2Fvless&security=tls&encryption=none&type=ws#VLESS_${username}
EOF

    # VMESS Configuration
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "VMESS_${username}",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "",
  "tls": "tls"
}
EOF
)

    cat > /etc/AutoscvpnMantap/users/$username/vmess.txt << EOF
====== VMESS CONFIGURATION ======
Remarks: ${domain}_VMESS_${username}
Domain: ${domain}
Port: 443
UUID: ${uuid}
AlterID: 0
Network: ws
Path: /vmess
TLS: tls
Created: $CURRENT_DATE
Expired: $exp_date

URL: vmess://$(echo $vmess_config | base64 -w 0)
EOF

    # TROJAN Configuration
    cat > /etc/AutoscvpnMantap/users/$username/trojan.txt << EOF
====== TROJAN CONFIGURATION ======
Remarks: ${domain}_TROJAN_${username}
Domain: ${domain}
Port: 443
Password: ${uuid}
Path: /trojan
Network: ws
TLS: tls
Created: $CURRENT_DATE
Expired: $exp_date

URL: trojan://${uuid}@${domain}:443?path=%2Ftrojan&security=tls&type=ws#TROJAN_${username}
EOF

    # Generate QR codes
    if command -v qrencode &> /dev/null; then
        for proto in vless vmess trojan; do
            grep "URL:" /etc/AutoscvpnMantap/users/$username/$proto.txt | cut -d ' ' -f2- | qrencode -s 10 -o /etc/AutoscvpnMantap/users/$username/$proto.png
        done
    fi
    
    # Restart Xray service
    systemctl restart xray
    
    # Show user information
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "           ${COLOR_GREEN}User Created Successfully${COLOR_NC}            "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_YELLOW}Username   :${COLOR_NC} $username"
    echo -e " ${COLOR_YELLOW}UUID      :${COLOR_NC} $uuid"
    echo -e " ${COLOR_YELLOW}Created   :${COLOR_NC} $CURRENT_DATE"
    echo -e " ${COLOR_YELLOW}Expired   :${COLOR_NC} $exp_date"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_GREEN}Configuration files saved in:${COLOR_NC}"
    echo -e " /etc/AutoscvpnMantap/users/$username/"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Log user creation
    echo "[$CURRENT_DATE UTC] Created Xray user: $username (exp: $exp_date) by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/xray.log
    
    read -p "Press enter to continue..."
}

# Delete Xray user
delete_xray_user() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "             ${COLOR_GREEN}Delete Xray User${COLOR_NC}                   "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # List existing users
    echo -e "${COLOR_YELLOW}Existing users:${COLOR_NC}"
    ls -1 /etc/AutoscvpnMantap/users/ | nl
    
    # Get user selection
    read -p "Select user number to delete (0 to cancel): " user_number
    
    if [ "$user_number" = "0" ]; then
        return
    fi
    
    username=$(ls -1 /etc/AutoscvpnMantap/users/ | sed -n "${user_number}p")
    
    if [ -z "$username" ]; then
        echo -e "${COLOR_RED}Invalid selection${COLOR_NC}"
        sleep 2
        return
    fi
    
    # Get user UUID
    uuid=$(jq -r '.uuid' /etc/AutoscvpnMantap/users/$username/info.json)
    
    # Remove user from Xray config
    for proto in vless vmess trojan; do
        jq --arg uuid "$uuid" \
           '.inbounds[] | select(.protocol == "'$proto'") .settings.clients = [.settings.clients[] | select(.id != $uuid)]' \
           /etc/AutoscvpnMantap/xray/config.json > /etc/AutoscvpnMantap/xray/config.json.tmp
        
        mv /etc/AutoscvpnMantap/xray/config.json.tmp /etc/AutoscvpnMantap/xray/config.json
    done
    
    # Remove user directory
    rm -rf /etc/AutoscvpnMantap/users/$username
    
    # Restart Xray service
    systemctl restart xray
    
    echo -e "${COLOR_GREEN}User $username deleted successfully${COLOR_NC}"
    
    # Log user deletion
    echo "[$CURRENT_DATE UTC] Deleted Xray user: $username by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/xray.log
    
    sleep 2
}

# List Xray users
list_xray_users() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Xray User List${COLOR_NC}                    "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    printf "%-4s %-20s %-20s %-10s\n" "No" "Username" "Expired" "Status"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    number=1
    for user in /etc/AutoscvpnMantap/users/*/info.json; do
        if [ -f "$user" ]; then
            username=$(jq -r '.username' "$user")
            expired=$(jq -r '.expired' "$user")
            
            # Check if expired
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
    read -p "Press enter to continue..."
}

# Export functions
export -f add_xray_user
export -f delete_xray_user
export -f list_xray_users