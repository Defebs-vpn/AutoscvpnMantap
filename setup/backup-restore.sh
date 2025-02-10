#!/bin/bash
# AutoscvpnMantap Backup & Restore Script
# Created: 2025-02-09 13:22:18 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Backup directory
BACKUP_DIR="/etc/AutoscvpnMantap/backup"
BACKUP_FILE="$BACKUP_DIR/backup-$CURRENT_DATE.tar.gz"

# Create backup
create_backup() {
    echo -e "${COLOR_YELLOW}Creating backup...${COLOR_NC}"
    
    # Create backup directory if not exists
    mkdir -p $BACKUP_DIR
    
    # Create tar archive
    tar -czf $BACKUP_FILE \
        /etc/AutoscvpnMantap/users \
        /etc/AutoscvpnMantap/xray \
        /etc/AutoscvpnMantap/ssh-ws \
        /etc/AutoscvpnMantap/nginx \
        /etc/AutoscvpnMantap/config \
        /etc/nginx/conf.d \
        2>/dev/null
    
    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}Backup created successfully: ${COLOR_NC}"
        echo -e "${COLOR_YELLOW}$BACKUP_FILE${COLOR_NC}"
        # Log backup creation
        echo "[$CURRENT_DATE UTC] Backup created: $BACKUP_FILE by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/backup.log
    else
        echo -e "${COLOR_RED}Backup creation failed${COLOR_NC}"
    fi
}

# Restore from backup
restore_backup() {
    echo -e "${COLOR_YELLOW}Available backups:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # List available backups
    ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null | nl
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Select backup number to restore (0 to cancel): " backup_number
    
    if [ "$backup_number" = "0" ]; then
        return
    fi
    
    selected_backup=$(ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null | sed -n "${backup_number}p")
    
    if [ -f "$selected_backup" ]; then
        echo -e "${COLOR_YELLOW}Restoring from backup: $selected_backup${COLOR_NC}"
        
        # Create temporary restore directory
        TEMP_RESTORE="/tmp/restore_$$"
        mkdir -p $TEMP_RESTORE
        
        # Extract backup
        tar -xzf $selected_backup -C $TEMP_RESTORE
        
        # Restore files
        cp -rf $TEMP_RESTORE/etc/AutoscvpnMantap/* /etc/AutoscvpnMantap/
        cp -rf $TEMP_RESTORE/etc/nginx/conf.d/* /etc/nginx/conf.d/
        
        # Clean up
        rm -rf $TEMP_RESTORE
        
        # Restart services
        systemctl restart nginx
        systemctl restart xray
        
        echo -e "${COLOR_GREEN}Restore completed successfully${COLOR_NC}"
        # Log restore operation
        echo "[$CURRENT_DATE UTC] Restore completed from: $selected_backup by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/backup.log
    else
        echo -e "${COLOR_RED}Invalid backup selection${COLOR_NC}"
    fi
}

# Show backup menu
show_backup_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Backup & Restore Menu${COLOR_NC}                "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Create Backup"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Restore from Backup"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • List Backups"
    echo -e " ${COLOR_GREEN}[4]${COLOR_NC} • Delete Old Backups"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# List backups
list_backups() {
    echo -e "${COLOR_YELLOW}Available backups:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    if ls $BACKUP_DIR/*.tar.gz >/dev/null 2>&1; then
        for backup in $BACKUP_DIR/*.tar.gz; do
            size=$(du -h "$backup" | cut -f1)
            date=$(stat -c %y "$backup" | cut -d. -f1)
            echo -e " ${COLOR_BLUE}➣${COLOR_NC} $(basename $backup)"
            echo -e "   Size: $size, Date: $date"
        done
    else
        echo -e "${COLOR_YELLOW}No backups found${COLOR_NC}"
    fi
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Press enter to continue..."
}

# Delete old backups
delete_old_backups() {
    echo -e "${COLOR_YELLOW}Delete backups older than:${COLOR_NC}"
    echo -e "1) 7 days"
    echo -e "2) 30 days"
    echo -e "3) Custom days"
    echo -e "0) Cancel"
    
    read -p "Select option: " del_option
    
    case $del_option in
        1) days=7 ;;
        2) days=30 ;;
        3) 
            read -p "Enter number of days: " days
            ;;
        0) return ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            return
            ;;
    esac
    
    find $BACKUP_DIR -name "backup-*.tar.gz" -mtime +$days -delete
    echo -e "${COLOR_GREEN}Deleted backups older than $days days${COLOR_NC}"
    # Log deletion
    echo "[$CURRENT_DATE UTC] Deleted backups older than $days days by $CURRENT_USER" >> /etc/AutoscvpnMantap/logs/backup.log
}

# Main loop
while true; do
    show_backup_menu
    read -p "Select option [0-4]: " option
    
    case $option in
        1) create_backup ;;
        2) restore_backup ;;
        3) list_backups ;;
        4) delete_old_backups ;;
        0) break ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 1
            ;;
    esac
done

# Return to main menu
menu