#!/bin/bash
# AutoscvpnMantap Xray Installation Script
# Created: 2025-02-09 13:31:53 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Xray version
XRAY_VERSION="1.8.4"

# Installation paths
XRAY_DIR="/etc/AutoscvpnMantap/xray"
XRAY_CONF="$XRAY_DIR/config.json"
LOG_DIR="/var/log/xray"

# Colors inherited from current-info.sh

echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e "          ${COLOR_GREEN}Xray Installation Script${COLOR_NC}              "
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e " ${COLOR_YELLOW}Date: $CURRENT_DATE UTC${COLOR_NC}"
echo -e " ${COLOR_YELLOW}User: $CURRENT_USER${COLOR_NC}"
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"

# Create necessary directories
mkdir -p $XRAY_DIR
mkdir -p $LOG_DIR

# Download and install Xray
install_xray() {
    echo -e "${COLOR_YELLOW}Installing Xray version $XRAY_VERSION...${COLOR_NC}"
    
    # Download Xray core
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
    
    # Check installation
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}Xray core installed successfully${COLOR_NC}"
    else
        echo -e "${COLOR_RED}Failed to install Xray core${COLOR_NC}"
        exit 1
    fi
}

# Configure Xray
configure_xray() {
    echo -e "${COLOR_YELLOW}Configuring Xray...${COLOR_NC}"
    
    # Basic configuration template
    cat > $XRAY_CONF << EOF
{
    "log": {
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vless"
                },
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/AutoscvpnMantap/cert/fullchain.pem",
                            "keyFile": "/etc/AutoscvpnMantap/cert/privkey.pem"
                        }
                    ]
                }
            }
        },
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmess"
                },
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/AutoscvpnMantap/cert/fullchain.pem",
                            "keyFile": "/etc/AutoscvpnMantap/cert/privkey.pem"
                        }
                    ]
                }
            }
        },
        {
            "port": 443,
            "protocol": "trojan",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/trojan"
                },
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/AutoscvpnMantap/cert/fullchain.pem",
                            "keyFile": "/etc/AutoscvpnMantap/cert/privkey.pem"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF

    # Create systemd service
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/AutoscvpnMantap/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # Set permissions
    chmod 644 $XRAY_CONF
    chmod 644 /etc/systemd/system/xray.service
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable xray
    
    echo -e "${COLOR_GREEN}Xray configured successfully${COLOR_NC}"
}

# Setup Xray service
setup_service() {
    echo -e "${COLOR_YELLOW}Setting up Xray service...${COLOR_NC}"
    
    # Start Xray service
    systemctl start xray
    
    # Check service status
    if systemctl is-active --quiet xray; then
        echo -e "${COLOR_GREEN}Xray service is running${COLOR_NC}"
    else
        echo -e "${COLOR_RED}Failed to start Xray service${COLOR_NC}"
        exit 1
    fi
}

# Main installation process
echo -e "${COLOR_YELLOW}Starting Xray installation...${COLOR_NC}"

# Install Xray
install_xray

# Configure Xray
configure_xray

# Setup service
setup_service

# Log installation
echo "[$CURRENT_DATE UTC] Xray installation completed by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/install.log

echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e "          ${COLOR_GREEN}Installation Complete!${COLOR_NC}                "
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e " ${COLOR_YELLOW}Xray Version: $XRAY_VERSION${COLOR_NC}"
echo -e " ${COLOR_YELLOW}Installation Date: $CURRENT_DATE UTC${COLOR_NC}"
echo -e " ${COLOR_YELLOW}Installed by: $CURRENT_USER${COLOR_NC}"
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"