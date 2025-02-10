#!/bin/bash
# AutoscvpnMantap User Creation Script
# Created: 2025-02-09 13:16:16 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

create_ssh_user() {
    local username=$1
    local password=$2
    local expired=$3
    
    # Create system user
    useradd -e "$expired" -s /bin/false $username
    echo "$username:$password" | chpasswd
    
    # Create user config
    mkdir -p /etc/AutoscvpnMantap/users/$username
    cat > /etc/AutoscvpnMantap/users/$username/config.conf << EOF
Username: $username
Password: $password
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER
EOF
    
    # Log creation
    echo "[$CURRENT_DATE UTC] Created user: $username (expires: $expired)" >> /etc/AutoscvpnMantap/logs/user.log
}

create_xray_user() {
    local username=$1
    local password=$2
    local expired=$3
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Create Xray user config
    mkdir -p /etc/AutoscvpnMantap/users/$username
    cat > /etc/AutoscvpnMantap/users/$username/xray.conf << EOF
Username: $username
UUID: $uuid
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER
EOF
    
    # Add to Xray config
    # Add your Xray configuration update logic here
    
    # Log creation
    echo "[$CURRENT_DATE UTC] Created Xray user: $username (expires: $expired)" >> /etc/AutoscvpnMantap/logs/user.log
}

# Main user creation function
create_user() {
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}Create New User${COLOR_NC}                    "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    read -p "Username: " username
    read -s -p "Password: " password
    echo ""
    read -p "Expired (days): " expired
    
    # Calculate expiry date
    expired_date=$(date -d "+${expired} days" +"%Y-%m-%d")
    
    echo -e "\n${COLOR_YELLOW}Select User Type:${COLOR_NC}"
    echo -e "1) SSH User"
    echo -e "2) Xray User"
    echo -e "3) Both"
    read -p "Choice [1-3]: " user_type
    
    case $user_type in
        1) create_ssh_user "$username" "$password" "$expired_date" ;;
        2) create_xray_user "$username" "$password" "$expired_date" ;;
        3)
            create_ssh_user "$username" "$password" "$expired_date"
            create_xray_user "$username" "$password" "$expired_date"
            ;;
        *) echo -e "${COLOR_RED}Invalid choice${COLOR_NC}" ;;
    esac
    
    echo -e "${COLOR_GREEN}User created successfully!${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Username: $username${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Password: $password${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Expired: $expired_date${COLOR_NC}"
    
    # Generate client config
    generate_client_config "$username" "$password" "$expired_date" "$user_type"
}

generate_client_config() {
    local username=$1
    local password=$2
    local expired=$3
    local user_type=$4
    
    # Create client config directory
    mkdir -p /etc/AutoscvpnMantap/users/$username/client-config
    
    if [[ "$user_type" == "1" || "$user_type" == "3" ]]; then
        # Generate SSH config
        cat > /etc/AutoscvpnMantap/users/$username/client-config/ssh-config.txt << EOF
====== SSH WEBSOCKET ACCOUNT ======
Host: $(curl -s ipv4.icanhazip.com)
Domain: $(cat /etc/AutoscvpnMantap/config/domain.conf)
Username: $username
Password: $password
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER

SSH Ports:
- 22 (Direct)
- 80 (WebSocket)
- 443 (WebSocket SSL)

WebSocket Path: /ssh-ws

=====================================
EOF
    fi
    
    if [[ "$user_type" == "2" || "$user_type" == "3" ]]; then
        # Generate Xray configs
        local uuid=$(cat /proc/sys/kernel/random/uuid)
        local domain=$(cat /etc/AutoscvpnMantap/config/domain.conf)
        
        # VLESS Config
        cat > /etc/AutoscvpnMantap/users/$username/client-config/vless-config.txt << EOF
====== VLESS ACCOUNT ======
Remarks: $(cat /etc/AutoscvpnMantap/config/domain.conf)_VLESS_$username
Domain: $(cat /etc/AutoscvpnMantap/config/domain.conf)
Port: 443
UUID: $uuid
Path: /vless
Network: ws
TLS: tls
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER

VLESS URL:
vless://$uuid@$domain:443?path=%2Fvless&security=tls&encryption=none&type=ws#VLESS_$username

=====================================
EOF

        # VMESS Config
        cat > /etc/AutoscvpnMantap/users/$username/client-config/vmess-config.txt << EOF
====== VMESS ACCOUNT ======
Remarks: $(cat /etc/AutoscvpnMantap/config/domain.conf)_VMESS_$username
Domain: $(cat /etc/AutoscvpnMantap/config/domain.conf)
Port: 443
UUID: $uuid
AlterID: 0
Security: auto
Network: ws
Path: /vmess
TLS: tls
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER

VMESS URL:
vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"VMESS_$username\",\"add\":\"$domain\",\"port\":\"443\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"\",\"tls\":\"tls\"}" | base64 -w 0)

=====================================
EOF

        # TROJAN Config
        cat > /etc/AutoscvpnMantap/users/$username/client-config/trojan-config.txt << EOF
====== TROJAN ACCOUNT ======
Remarks: $(cat /etc/AutoscvpnMantap/config/domain.conf)_TROJAN_$username
Domain: $(cat /etc/AutoscvpnMantap/config/domain.conf)
Port: 443
Password: $uuid
Path: /trojan
Network: ws
TLS: tls
Created: $CURRENT_DATE UTC
Expired: $expired
Created by: $CURRENT_USER

TROJAN URL:
trojan://$uuid@$domain:443?path=%2Ftrojan&security=tls&type=ws#TROJAN_$username

=====================================
EOF

        # Update Xray config
        update_xray_config "$username" "$uuid"
    fi
    
    # Create QR codes for configs
    generate_qr_codes "$username"
}

update_xray_config() {
    local username=$1
    local uuid=$2
    
    # Backup current config
    cp /etc/AutoscvpnMantap/xray/config.json /etc/AutoscvpnMantap/xray/config.json.bak
    
    # Add user to each protocol
    for protocol in vless vmess trojan; do
        jq --arg user "$username" \
           --arg uuid "$uuid" \
           --arg path "/$protocol" \
           '.inbounds[] | select(.protocol == $protocol) .settings.clients += [{id: $uuid, email: $user}]' \
           /etc/AutoscvpnMantap/xray/config.json > /etc/AutoscvpnMantap/xray/config.json.tmp
        
        mv /etc/AutoscvpnMantap/xray/config.json.tmp /etc/AutoscvpnMantap/xray/config.json
    done
    
    # Restart Xray service
    systemctl restart xray
}

generate_qr_codes() {
    local username=$1
    local config_dir="/etc/AutoscvpnMantap/users/$username/client-config"
    
    # Install qrencode if not present
    if ! command -v qrencode &> /dev/null; then
        apt-get install -y qrencode
    fi
    
    # Generate QR codes for each config
    if [ -f "$config_dir/vless-config.txt" ]; then
        grep "vless://" "$config_dir/vless-config.txt" | qrencode -s 10 -o "$config_dir/vless-qr.png"
    fi
    
    if [ -f "$config_dir/vmess-config.txt" ]; then
        grep "vmess://" "$config_dir/vmess-config.txt" | qrencode -s 10 -o "$config_dir/vmess-qr.png"
    fi
    
    if [ -f "$config_dir/trojan-config.txt" ]; then
        grep "trojan://" "$config_dir/trojan-config.txt" | qrencode -s 10 -o "$config_dir/trojan-qr.png"
    fi
}

# Show created user info
show_user_info() {
    local username=$1
    local config_dir="/etc/AutoscvpnMantap/users/$username/client-config"
    
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}User Account Created${COLOR_NC}                "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Show SSH config if exists
    if [ -f "$config_dir/ssh-config.txt" ]; then
        echo -e "${COLOR_YELLOW}SSH WebSocket Configuration:${COLOR_NC}"
        cat "$config_dir/ssh-config.txt"
        echo ""
    fi
    
    # Show Xray configs if exist
    for protocol in vless vmess trojan; do
        if [ -f "$config_dir/$protocol-config.txt" ]; then
            echo -e "${COLOR_YELLOW}${protocol^^} Configuration:${COLOR_NC}"
            cat "$config_dir/$protocol-config.txt"
            echo ""
        fi
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "${COLOR_YELLOW}QR codes have been generated in: $config_dir${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Log user creation
    echo "[$CURRENT_DATE UTC] New user created: $username by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/user.log
}

# Export functions
export -f create_user
export -f generate_client_config
export -f update_xray_config
export -f generate_qr_codes
export -f show_user_info