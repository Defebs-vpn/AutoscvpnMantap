#!/bin/bash
# AutoscvpnMantap SSH WebSocket Installation
# Created: 2025-02-09 14:51:48 UTC
# Author: Defebs-vpn

# Source current info and configs
source /etc/AutoscvpnMantap/menu/current-info.sh
source /etc/AutoscvpnMantap/config/variable.conf
source /etc/AutoscvpnMantap/config/port.conf

# Create installation directories
mkdir -p /etc/AutoscvpnMantap/ssh-ws
mkdir -p /etc/AutoscvpnMantap/logs/ssh-ws

# Display banner
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e "        ${COLOR_GREEN}SSH WebSocket Installation${COLOR_NC}              "
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
echo -e " ${COLOR_YELLOW}Date: $CURRENT_DATE UTC${COLOR_NC}"
echo -e " ${COLOR_YELLOW}User: $CURRENT_USER${COLOR_NC}"
echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"

# Install required packages
install_requirements() {
    echo -e "${COLOR_YELLOW}Installing required packages...${COLOR_NC}"
    apt-get update
    apt-get install -y python3 python3-pip nginx certbot
    pip3 install websockets
    
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}Package installation successful${COLOR_NC}"
    else
        echo -e "${COLOR_RED}Package installation failed${COLOR_NC}"
        exit 1
    fi
}

# Configure SSH
configure_ssh() {
    echo -e "${COLOR_YELLOW}Configuring SSH...${COLOR_NC}"
    
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    # Update SSH configuration
    cat > /etc/ssh/sshd_config << EOF
Port $SSH_PORT1
Port $SSH_PORT2
ListenAddress 0.0.0.0
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
SyslogFacility AUTH
LogLevel INFO
PermitRootLogin yes
StrictModes yes
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    
    # Restart SSH service
    systemctl restart ssh
    
    echo -e "${COLOR_GREEN}SSH configuration updated${COLOR_NC}"
}

# Install SSH WebSocket Proxy
install_ws_proxy() {
    echo -e "${COLOR_YELLOW}Installing SSH WebSocket Proxy...${COLOR_NC}"
    
    # Create WebSocket Proxy Script
    cat > /etc/AutoscvpnMantap/ssh-ws/proxy.py << EOF
import asyncio
import websockets
import socket
import threading
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    filename='/etc/AutoscvpnMantap/logs/ssh-ws/proxy.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

async def handle_connection(websocket, path):
    try:
        # Create TCP connection to SSH server
        ssh_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_sock.connect(('127.0.0.1', $SSH_PORT1))
        
        # Handle WebSocket data
        async def ws_to_ssh():
            try:
                while True:
                    data = await websocket.recv()
                    if not data:
                        break
                    ssh_sock.send(data)
            except Exception as e:
                logging.error(f"WS to SSH error: {str(e)}")
        
        # Handle SSH data
        async def ssh_to_ws():
            try:
                while True:
                    data = ssh_sock.recv(4096)
                    if not data:
                        break
                    await websocket.send(data)
            except Exception as e:
                logging.error(f"SSH to WS error: {str(e)}")
        
        # Run both handlers
        await asyncio.gather(
            ws_to_ssh(),
            ssh_to_ws()
        )
    
    except Exception as e:
        logging.error(f"Connection error: {str(e)}")
    finally:
        ssh_sock.close()

# Start WebSocket server
async def start_server():
    logging.info("Starting SSH WebSocket Proxy")
    async with websockets.serve(handle_connection, "0.0.0.0", $SSH_WS_PORT):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(start_server())
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/ssh-ws.service << EOF
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/AutoscvpnMantap/ssh-ws
ExecStart=/usr/bin/python3 /etc/AutoscvpnMantap/ssh-ws/proxy.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Set permissions
    chmod +x /etc/AutoscvpnMantap/ssh-ws/proxy.py
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable ssh-ws
    systemctl start ssh-ws
    
    echo -e "${COLOR_GREEN}SSH WebSocket Proxy installed${COLOR_NC}"
}

# Configure Nginx
configure_nginx() {
    echo -e "${COLOR_YELLOW}Configuring Nginx...${COLOR_NC}"
    
    # Copy configuration
    cp /etc/AutoscvpnMantap/ssh-ws/ssh-ws-config.conf /etc/nginx/conf.d/
    
    # Test and reload Nginx
    nginx -t
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        echo -e "${COLOR_GREEN}Nginx configuration updated${COLOR_NC}"
    else
        echo -e "${COLOR_RED}Nginx configuration error${COLOR_NC}"
        exit 1
    fi
}

# Main installation process
main() {
    # Install requirements
    install_requirements
    
    # Configure SSH
    configure_ssh
    
    # Install WebSocket Proxy
    install_ws_proxy
    
    # Configure Nginx
    configure_nginx
    
    # Display completion message
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "      ${COLOR_GREEN}SSH WebSocket Installation Complete${COLOR_NC}        "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_YELLOW}SSH Ports: $SSH_PORT1, $SSH_PORT2${COLOR_NC}"
    echo -e " ${COLOR_YELLOW}WebSocket Port: $SSH_WS_PORT${COLOR_NC}"
    echo -e " ${COLOR_YELLOW}WSS Port: $SSH_WSS_PORT${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Log installation
    echo "[$CURRENT_DATE UTC] SSH WebSocket installation completed by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/install.log
}

# Run main installation
main