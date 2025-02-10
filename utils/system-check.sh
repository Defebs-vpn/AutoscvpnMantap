#!/bin/bash
# AutoscvpnMantap System Check Utility
# Created: 2025-02-09 14:40:55 UTC
# Author: Defebs-vpn

# Source current info and configs
source /etc/AutoscvpnMantap/menu/current-info.sh
source /etc/AutoscvpnMantap/config/variable.conf

# Function to check system resources
check_system_resources() {
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}System Resources Check${COLOR_NC}              "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    echo -e " ${COLOR_YELLOW}CPU Usage${COLOR_NC}: $cpu_usage%"
    
    # Memory Usage
    mem_total=$(free -m | awk 'NR==2{printf "%.2f", $2/1024}')
    mem_used=$(free -m | awk 'NR==2{printf "%.2f", $3/1024}')
    mem_usage=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
    echo -e " ${COLOR_YELLOW}Memory Usage${COLOR_NC}: ${mem_used}GB / ${mem_total}GB (${mem_usage}%)"
    
    # Disk Usage
    disk_total=$(df -h / | awk 'NR==2{print $2}')
    disk_used=$(df -h / | awk 'NR==2{print $3}')
    disk_usage=$(df -h / | awk 'NR==2{print $5}')
    echo -e " ${COLOR_YELLOW}Disk Usage${COLOR_NC}: ${disk_used} / ${disk_total} (${disk_usage})"
    
    # Load Average
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e " ${COLOR_YELLOW}Load Average${COLOR_NC}: $load_avg"
}

# Function to check running services
check_services() {
    echo -e "\n${COLOR_YELLOW}Service Status:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    services=("nginx" "xray" "ssh" "dropbear" "stunnel4" "fail2ban")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            echo -e " ${COLOR_GREEN}[ACTIVE]${COLOR_NC} $service"
        else
            echo -e " ${COLOR_RED}[INACTIVE]${COLOR_NC} $service"
        fi
    done
}

# Function to check network status
check_network() {
    echo -e "\n${COLOR_YELLOW}Network Status:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Check Internet Connection
    if ping -c 1 google.com &> /dev/null; then
        echo -e " ${COLOR_GREEN}[OK]${COLOR_NC} Internet Connection"
    else
        echo -e " ${COLOR_RED}[FAIL]${COLOR_NC} Internet Connection"
    fi
    
    # Check DNS Resolution
    if nslookup google.com &> /dev/null; then
        echo -e " ${COLOR_GREEN}[OK]${COLOR_NC} DNS Resolution"
    else
        echo -e " ${COLOR_RED}[FAIL]${COLOR_NC} DNS Resolution"
    fi
    
    # Network Interface Status
    echo -e "\n${COLOR_YELLOW}Network Interfaces:${COLOR_NC}"
    ip -br addr show
}

# Function to check security status
check_security() {
    echo -e "\n${COLOR_YELLOW}Security Check:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Check Fail2ban Status
    if systemctl is-active --quiet fail2ban; then
        echo -e " ${COLOR_GREEN}[ENABLED]${COLOR_NC} Fail2ban"
        fail2ban-client status | grep "Jail list"
    else
        echo -e " ${COLOR_RED}[DISABLED]${COLOR_NC} Fail2ban"
    fi
    
    # Check UFW Status
    if systemctl is-active --quiet ufw; then
        echo -e " ${COLOR_GREEN}[ENABLED]${COLOR_NC} UFW Firewall"
        ufw status | grep "Status"
    else
        echo -e " ${COLOR_RED}[DISABLED]${COLOR_NC} UFW Firewall"
    fi
    
    # SSL Certificate Check
    if [ -f "$SSL_PATH/fullchain.pem" ]; then
        ssl_exp=$(openssl x509 -enddate -noout -in "$SSL_PATH/fullchain.pem" | cut -d= -f2)
        echo -e " ${COLOR_GREEN}[OK]${COLOR_NC} SSL Certificate (Expires: $ssl_exp)"
    else
        echo -e " ${COLOR_RED}[MISSING]${COLOR_NC} SSL Certificate"
    fi
}

# Main function
main() {
    clear
    show_system_info
    check_system_resources
    check_services
    check_network
    check_security
    
    echo -e "\n${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " Last Check: $CURRENT_DATE UTC"
    echo -e " Checked by: $CURRENT_USER"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Log the check
    echo "[$CURRENT_DATE UTC] System check performed by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/system-check.log
}

# Run main function
main