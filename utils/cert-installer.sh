#!/bin/bash
# AutoscvpnMantap Certificate Installer
# Created: 2025-02-09 14:40:55 UTC
# Author: Defebs-vpn

# Source current info and configs
source /etc/AutoscvpnMantap/menu/current-info.sh
source /etc/AutoscvpnMantap/config/variable.conf

# Function to install certbot
install_certbot() {
    echo -e "${COLOR_YELLOW}Installing Certbot...${COLOR_NC}"
    apt-get update
    apt-get install -y certbot
    
    if command -v certbot &> /dev/null; then
        echo -e "${COLOR_GREEN}Certbot installed successfully${COLOR_NC}"
    else
        echo -e "${COLOR_RED}Failed to install Certbot${COLOR_NC}"
        exit 1
    fi
}

# Function to request SSL certificate
request_ssl_cert() {
    local domain=$1
    echo -e "${COLOR_YELLOW}Requesting SSL certificate for $domain...${COLOR_NC}"
    
    # Stop webserver temporarily
    systemctl stop nginx
    
    # Request certificate
    certbot certonly --standalone --preferred-challenges http \
        --agree-tos --email admin@$domain -d $domain
    
    # Check if certificate was obtained
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        # Copy certificates to AutoscvpnMantap directory
        mkdir -p $SSL_PATH
        cp /etc/letsencrypt/live/$domain/fullchain.pem $SSL_PATH/
        cp /etc/letsencrypt/live/$domain/privkey.pem $SSL_PATH/
        
        # Set proper permissions
        chmod 644 $SSL_PATH/fullchain.pem
        chmod 644 $SSL_PATH/privkey.pem
        
        # Update domain in config
        echo "$domain" > /etc/AutoscvpnMantap/config/domain.conf
        
        echo -e "${COLOR_GREEN}SSL Certificate obtained successfully${COLOR_NC}"
        
        # Restart services
        systemctl restart nginx
        systemctl restart xray
        
        # Log certificate installation
        echo "[$CURRENT_DATE UTC] SSL Certificate installed for $domain by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/cert.log
    else
        echo -e "${COLOR_RED}Failed to obtain SSL certificate${COLOR_NC}"
        exit 1
    fi
}

# Function to check certificate expiry
check_cert_expiry() {
    local domain=$1
    if [ -f "$SSL_PATH/fullchain.pem" ]; then
        local exp_date=$(openssl x509 -enddate -noout -in "$SSL_PATH/fullchain.pem" | cut -d= -f2)
        local exp_epoch=$(date -d "$exp_date" +%s)
        local current_epoch=$(date +%s)
        local days_left=$(( ($exp_epoch - $current_epoch) / 86400 ))
        
        echo -e "${COLOR_YELLOW}Certificate Status:${COLOR_NC}"
        echo -e "Domain: $domain"
        echo -e "Expires: $exp_date"
        echo -e "Days until expiry: $days_left"
        
        if [ $days_left -lt 30 ]; then
            echo -e "${COLOR_RED}Warning: Certificate will expire soon${COLOR_NC}"
        fi
    else
        echo -e "${COLOR_RED}No certificate found${COLOR_NC}"
    fi
}

# Function to renew certificate
renew_certificate() {
    echo -e "${COLOR_YELLOW}Renewing SSL certificate...${COLOR_NC}"
    
    # Stop webserver
    systemctl stop nginx
    
    # Attempt renewal
    certbot renew
    
    # Check renewal status
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}Certificate renewed successfully${COLOR_NC}"
        
        # Update certificates in AutoscvpnMantap directory
        local domain=$(cat /etc/AutoscvpnMantap/config/domain.conf)
        cp /etc/letsencrypt/live/$domain/fullchain.pem $SSL_PATH/
        cp /etc/letsencrypt/live/$domain/privkey.pem $SSL_PATH/
        
        # Restart services
        systemctl restart nginx
        systemctl restart xray
        
        # Log renewal
        echo "[$CURRENT_DATE UTC] SSL Certificate renewed by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/cert.log
    else
        echo -e "${COLOR_RED}Certificate renewal failed${COLOR_NC}"
    fi
}

# Show certificate menu
show_cert_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "           ${COLOR_GREEN}SSL Certificate Manager${COLOR_NC}              "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Install New Certificate"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Check Certificate Status"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • Renew Certificate"
    echo -e " ${COLOR_GREEN}[4]${COLOR_NC} • View Certificate Info"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main function
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${COLOR_RED}Please run as root${COLOR_NC}"
        exit 1
    fi
    
    while true; do
        show_cert_menu
        read -p "Select option [0-4]: " option
        
        case $option in
            1)
                read -p "Enter domain name: " domain
                if [ -z "$domain" ]; then
                    echo -e "${COLOR_RED}Domain name cannot be empty${COLOR_NC}"
                    sleep 2
                    continue
                fi
                clear
                install_certbot
                request_ssl_cert $domain
                read -p "Press enter to continue..."
                ;;
            2)
                clear
                domain=$(cat /etc/AutoscvpnMantap/config/domain.conf)
                check_cert_expiry $domain
                read -p "Press enter to continue..."
                ;;
            3)
                clear
                renew_certificate
                read -p "Press enter to continue..."
                ;;
            4)
                clear
                if [ -f "$SSL_PATH/fullchain.pem" ]; then
                    echo -e "${COLOR_YELLOW}Certificate Information:${COLOR_NC}"
                    openssl x509 -in "$SSL_PATH/fullchain.pem" -text -noout
                else
                    echo -e "${COLOR_RED}No certificate found${COLOR_NC}"
                fi
                read -p "Press enter to continue..."
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