#!/bin/bash
# AutoscvpnMantap User Management Menu
# Created: 2025-02-09 13:16:16 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# User Management Functions
create_user() {
    echo -e "${COLOR_YELLOW}Create New User${COLOR_NC}"
    read -p "Username: " username
    read -s -p "Password: " password
    echo ""
    
    # Add user creation logic here
    useradd -m -s /bin/false $username
    echo "$username:$password" | chpasswd
    
    echo -e "${COLOR_GREEN}User $username created successfully${COLOR_NC}"
    sleep 2
}

delete_user() {
    echo -e "${COLOR_YELLOW}Delete User${COLOR_NC}"
    read -p "Username to delete: " username
    
    # Add user deletion logic here
    userdel -r $username
    
    echo -e "${COLOR_GREEN}User $username deleted successfully${COLOR_NC}"
    sleep 2
}

list_users() {
    echo -e "${COLOR_YELLOW}Current Users:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "USERNAME          EXPIRED DATE         STATUS"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    # Add user listing logic here
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read user; do
        exp=$(chage -l $user | grep "Account expires" | cut -d: -f2)
        if [[ $(who | grep -c $user) -gt 0 ]]; then
            status="${COLOR_GREEN}ONLINE${COLOR_NC}"
        else
            status="${COLOR_RED}OFFLINE${COLOR_NC}"
        fi
        printf "%-16s %-19s %s\n" "$user" "$exp" "$status"
    done
    
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    read -p "Press enter to continue..."
}

change_password() {
    echo -e "${COLOR_YELLOW}Change User Password${COLOR_NC}"
    read -p "Username: " username
    read -s -p "New Password: " password
    echo ""
    
    # Add password change logic here
    echo "$username:$password" | chpasswd
    
    echo -e "${COLOR_GREEN}Password changed successfully for $username${COLOR_NC}"
    sleep 2
}

# User Menu Display
show_user_menu() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "              ${COLOR_GREEN}User Management${COLOR_NC}                    "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Create User"
    echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Delete User"
    echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • List Users"
    echo -e " ${COLOR_GREEN}[4]${COLOR_NC} • Change Password"
    echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
}

# Main Loop
while true; do
    show_user_menu
    read -p "Select option [0-4]: " option
    
    case $option in
        1) create_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) change_password ;;
        0) break ;;
        *) 
            echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
            sleep 1
            ;;
    esac
done

# Return to main menu
menu