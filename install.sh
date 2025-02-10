#!/bin/bash
# AutoscvpnMantap Main Installation Script
# Created: 2025-02-10 11:48:19 UTC
# Author: Defebs-vpn

# Define colors
NC='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'

# Base directory
BASE_DIR="/etc/AutoscvpnMantap"
CURRENT_DATE="2025-02-10 11:48:19"
CURRENT_USER="Defebs-vpn"

# Function to display banner
show_banner() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "          ${GREEN}AutoscvpnMantap Installation${NC}           "
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${YELLOW}Date: $CURRENT_DATE UTC${NC}"
    echo -e " ${YELLOW}User: $CURRENT_USER${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to create directory structure
create_directories() {
    echo -e "${YELLOW}Creating directory structure...${NC}"
    
    # Main directories
    mkdir -p $BASE_DIR/{config,menu,setup,utils}
    
    # Menu subdirectories
    mkdir -p $BASE_DIR/menu/xray
    
    # Setup subdirectories
    mkdir -p $BASE_DIR/setup/{nginx/conf.d,ssh-ws/service,xray/service,utils}
    
    # Logs directory
    mkdir -p $BASE_DIR/logs/{ssh,xray,nginx,system}
    
    echo -e "${GREEN}Directory structure created successfully${NC}"
}

# Function to copy configuration files
copy_configs() {
    echo -e "${YELLOW}Copying configuration files...${NC}"
    
    # Copy config files
    cp config/port.conf $BASE_DIR/config/
    cp config/variable.conf $BASE_DIR/config/
    
    # Copy menu files
    cp menu/xray/{management-functions.sh,traffic-monitor.sh,user-functions.sh} $BASE_DIR/menu/xray/
    cp menu/{current-info.sh,main-menu.sh,menu.sh,monitor-menu.sh,status-menu.sh,user-menu.sh,xray-menu.sh} $BASE_DIR/menu/
    
    # Copy setup files
    cp setup/nginx/conf.d/ws-stunnel.conf $BASE_DIR/setup/nginx/conf.d/
    cp setup/ssh-ws/service/ws-openssh.service $BASE_DIR/setup/ssh-ws/service/
    cp setup/ssh-ws/{ssh-ws-config.conf,ssh-ws-install.sh} $BASE_DIR/setup/ssh-ws/
    cp setup/utils/logger.sh $BASE_DIR/setup/utils/
    cp setup/xray/service/xray.service $BASE_DIR/setup/xray/service/
    cp setup/xray/{xray-config.json,xray-install.sh} $BASE_DIR/setup/xray/
    cp setup/{backup-restore.sh,create-user.sh,security-menu.sh} $BASE_DIR/setup/
    
    # Copy utility files
    cp utils/{cert-installer.sh,port-check.sh,system-check.sh} $BASE_DIR/utils/
    
    echo -e "${GREEN}Configuration files copied successfully${NC}"
}

# Function to set permissions
set_permissions() {
    echo -e "${YELLOW}Setting file permissions...${NC}"
    
    # Set directory permissions
    chmod 755 $BASE_DIR
    chmod -R 755 $BASE_DIR/menu
    chmod -R 755 $BASE_DIR/utils
    chmod -R 755 $BASE_DIR/setup
    
    # Set executable permissions for scripts
    find $BASE_DIR -type f -name "*.sh" -exec chmod +x {} \;
    
    # Set config file permissions
    chmod 644 $BASE_DIR/config/*.conf
    chmod 644 $BASE_DIR/setup/xray/xray-config.json
    chmod 644 $BASE_DIR/setup/nginx/conf.d/*.conf
    chmod 644 $BASE_DIR/setup/ssh-ws/*.conf
    
    # Set service file permissions
    chmod 644 $BASE_DIR/setup/xray/service/xray.service
    chmod 644 $BASE_DIR/setup/ssh-ws/service/ws-openssh.service
    
    echo -e "${GREEN}Permissions set successfully${NC}"
}

# Function to install services
install_services() {
    echo -e "${YELLOW}Installing services...${NC}"
    
    # Install SSH WebSocket
    bash $BASE_DIR/setup/ssh-ws/ssh-ws-install.sh
    
    # Install Xray
    bash $BASE_DIR/setup/xray/xray-install.sh
    
    # Copy and enable services
    cp $BASE_DIR/setup/xray/service/xray.service /etc/systemd/system/
    cp $BASE_DIR/setup/ssh-ws/service/ws-openssh.service /etc/systemd/system/
    
    systemctl daemon-reload
    systemctl enable xray
    systemctl enable ws-openssh
    
    echo -e "${GREEN}Services installed successfully${NC}"
}

# Function to configure Nginx
configure_nginx() {
    echo -e "${YELLOW}Configuring Nginx...${NC}"
    
    # Copy Nginx configurations
    cp $BASE_DIR/setup/nginx/conf.d/ws-stunnel.conf /etc/nginx/conf.d/
    
    # Test and reload Nginx
    nginx -t && systemctl reload nginx
    
    echo -e "${GREEN}Nginx configured successfully${NC}"
}

# Function to setup SSL certificate
setup_ssl() {
    echo -e "${YELLOW}Setting up SSL certificate...${NC}"
    bash $BASE_DIR/utils/cert-installer.sh
    echo -e "${GREEN}SSL certificate setup completed${NC}"
}

# Function to perform system checks
perform_checks() {
    echo -e "${YELLOW}Performing system checks...${NC}"
    bash $BASE_DIR/utils/system-check.sh
    bash $BASE_DIR/utils/port-check.sh
    echo -e "${GREEN}System checks completed${NC}"
}

# Function to install required dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    
    # Update package list
    apt-get update
    
    # Install essential packages
    apt-get install -y \
        curl \
        wget \
        zip \
        unzip \
        git \
        vim \
        nano \
        iptables \
        net-tools \
        cron \
        socat \
        python3 \
        python3-pip \
        fail2ban \
        vnstat \
        tree \
        speedtest-cli \
        jq \
        nginx \
        certbot \
        dropbear \
        stunnel4
        
    echo -e "${GREEN}Dependencies installed successfully${NC}"
}

# Function to configure system settings
configure_system() {
    echo -e "${YELLOW}Configuring system settings...${NC}"
    
    # Set timezone
    timedatectl set-timezone Asia/Jakarta
    
    # Configure SSH
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    systemctl restart ssh
    
    # Configure fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    systemctl restart fail2ban
    
    # Enable BBR
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    
    echo -e "${GREEN}System settings configured successfully${NC}"
}

# Function to setup users and permissions
setup_users() {
    echo -e "${YELLOW}Setting up users and permissions...${NC}"
    
    # Create system user for services
    useradd -r -M -s /sbin/nologin autoscvpn
    
    # Set ownership of service directories
    chown -R autoscvpn:autoscvpn $BASE_DIR/logs
    
    echo -e "${GREEN}Users and permissions setup completed${NC}"
}

# Function to configure firewall
setup_firewall() {
    echo -e "${YELLOW}Configuring firewall...${NC}"
    
    # Flush existing rules
    iptables -F
    iptables -X
    
    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow HTTP/HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Allow WebSocket ports
    iptables -A INPUT -p tcp --dport 8880 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
    
    # Save rules
    iptables-save > /etc/iptables.rules
    
    # Create restore script
    cat > /etc/network/if-pre-up.d/iptables-restore << 'EOF'
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF
    
    chmod +x /etc/network/if-pre-up.d/iptables-restore
    
    echo -e "${GREEN}Firewall configured successfully${NC}"
}

# Function to setup cron jobs
setup_cron_jobs() {
    echo -e "${YELLOW}Setting up cron jobs...${NC}"
    
    # Backup crontab
    crontab -l > /tmp/crontab.bak 2>/dev/null
    
    # Add new cron jobs
    cat >> /tmp/crontab.bak << 'EOF'
# AutoscvpnMantap Cron Jobs
0 0 * * * /etc/AutoscvpnMantap/utils/cert-installer.sh renew >/dev/null 2>&1
0 */6 * * * /etc/AutoscvpnMantap/utils/system-check.sh >/dev/null 2>&1
*/10 * * * * /etc/AutoscvpnMantap/menu/xray/traffic-monitor.sh update >/dev/null 2>&1
0 0 * * * /etc/AutoscvpnMantap/setup/backup-restore.sh backup >/dev/null 2>&1
EOF
    
    # Install new crontab
    crontab /tmp/crontab.bak
    rm /tmp/crontab.bak
    
    echo -e "${GREEN}Cron jobs setup completed${NC}"
}

# Function to setup logging
setup_logging() {
    echo -e "${YELLOW}Setting up logging...${NC}"
    
    # Create log directories if they don't exist
    mkdir -p $BASE_DIR/logs/{ssh,xray,nginx,system}
    
    # Setup log rotation
    cat > /etc/logrotate.d/autoscvpn << 'EOF'
$BASE_DIR/logs/ssh/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    missingok
}

$BASE_DIR/logs/xray/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    missingok
}

$BASE_DIR/logs/nginx/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    missingok
}

$BASE_DIR/logs/system/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    missingok
}
EOF
    
    # Create initial log files
    touch $BASE_DIR/logs/system/install.log
    touch $BASE_DIR/logs/system/error.log
    
    echo -e "${GREEN}Logging setup completed${NC}"
}

# Main installation function
main_install() {
    show_banner
    
    # Check root privileges
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
    
    # Begin installation
    create_directories
    install_dependencies
    configure_system
    setup_users
    copy_configs
    set_permissions
    setup_firewall
    install_services
    configure_nginx
    setup_ssl
    setup_cron_jobs
    setup_logging
    perform_checks
    
    # Installation complete
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "      ${GREEN}AutoscvpnMantap Installation Complete${NC}        "
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${YELLOW}Installation Date: $CURRENT_DATE UTC${NC}"
    echo -e " ${YELLOW}Installed by: $CURRENT_USER${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Log installation
    echo "[$CURRENT_DATE UTC] Installation completed by $CURRENT_USER" >> $BASE_DIR/logs/system/install.log
}

# Run installation
main_install
