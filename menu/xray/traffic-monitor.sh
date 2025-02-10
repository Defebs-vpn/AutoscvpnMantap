#!/bin/bash
# AutoscvpnMantap Xray Traffic Monitor
# Created: 2025-02-09 14:16:14 UTC
# Author: Defebs-vpn

# Source current info
source /etc/AutoscvpnMantap/menu/current-info.sh

# Traffic monitoring functions
monitor_traffic() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Xray Traffic Monitor${COLOR_NC}                "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "${COLOR_YELLOW}Current Time: $CURRENT_DATE UTC${COLOR_NC}"
    
    # Initialize counters
    declare -A protocol_connections
    declare -A protocol_bandwidth
    
    # Monitor each protocol
    for proto in vless vmess trojan; do
        protocol_connections[$proto]=0
        protocol_bandwidth[$proto]=0
        
        # Get active connections
        connections=$(netstat -tnp | grep xray | grep ESTABLISHED | grep -i $proto | wc -l)
        protocol_connections[$proto]=$connections
        
        # Get bandwidth usage (if vnstat is installed)
        if command -v vnstat &> /dev/null; then
            bandwidth=$(vnstat -h 1 | grep $(date +%H:%M) | awk '{print $2 $3}')
            protocol_bandwidth[$proto]=$bandwidth
        fi
    done
    
    # Display traffic statistics
    echo -e "\n${COLOR_YELLOW}Protocol Statistics:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    printf "%-15s %-20s %-15s\n" "Protocol" "Active Connections" "Bandwidth"
    
    for proto in vless vmess trojan; do
        printf "%-15s %-20s %-15s\n" \
            "${proto^^}" \
            "${protocol_connections[$proto]}" \
            "${protocol_bandwidth[$proto]:-N/A}"
    done
    
    # Display active users
    echo -e "\n${COLOR_YELLOW}Active Users:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    printf "%-4s %-20s %-15s %-15s %-15s\n" "No" "Username" "Protocol" "IP Address" "Duration"
    
    number=1
    for proto in vless vmess trojan; do
        netstat -tnp | grep xray | grep ESTABLISHED | grep -i $proto | while read line; do
            ip=$(echo $line | awk '{print $5}' | cut -d: -f1)
            port=$(echo $line | awk '{print $5}' | cut -d: -f2)
            pid=$(echo $line | awk '{print $7}' | cut -d/ -f1)
            
            # Get connection duration
            if [ -d "/proc/$pid" ]; then
                start_time=$(stat -c %Y /proc/$pid)
                current_time=$(date +%s)
                duration=$((current_time - start_time))
                duration_formatted=$(date -u -d @${duration} +"%H:%M:%S")
            else
                duration_formatted="N/A"
            fi
            
            # Get username from connection
            username=$(grep -l "$ip" /etc/AutoscvpnMantap/users/*/info.json | cut -d/ -f5)
            
            if [ ! -z "$username" ]; then
                printf "%-4s %-20s %-15s %-15s %-15s\n" \
                    "$number" \
                    "$username" \
                    "${proto^^}" \
                    "$ip" \
                    "$duration_formatted"
                ((number++))
            fi
        done
    done
    
    if [ $number -eq 1 ]; then
        echo -e "${COLOR_YELLOW}No active connections${COLOR_NC}"
    fi
    
    # Display system load
    echo -e "\n${COLOR_YELLOW}System Load:${COLOR_NC}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    mem_used=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    disk_used=$(df -h / | awk 'NR==2{print $5}')
    
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} CPU Load    : $cpu_load%"
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Memory Used : $mem_used"
    echo -e " ${COLOR_BLUE}➣${COLOR_NC} Disk Used   : $disk_used"
    
    # Save traffic statistics
    save_traffic_stats
}

# Save traffic statistics
save_traffic_stats() {
    local stats_file="/etc/AutoscvpnMantap/logs/traffic_stats.log"
    
    # Create stats entry
    local stats_entry="[$CURRENT_DATE UTC]"
    for proto in vless vmess trojan; do
        stats_entry="$stats_entry [$proto: ${protocol_connections[$proto]} conn, ${protocol_bandwidth[$proto]:-0} bandwidth]"
    done
    
    # Append to log file
    echo "$stats_entry" >> $stats_file
}

# Show traffic history
show_traffic_history() {
    clear
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    echo -e "            ${COLOR_GREEN}Traffic History${COLOR_NC}                     "
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
    
    if [ -f "/etc/AutoscvpnMantap/logs/traffic_stats.log" ]; then
        tail -n 50 "/etc/AutoscvpnMantap/logs/traffic_stats.log"
    else
        echo -e "${COLOR_YELLOW}No traffic history available${COLOR_NC}"
    fi
}

# Main traffic monitoring menu
show_traffic_menu() {
    while true; do
        clear
        echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
        echo -e "            ${COLOR_GREEN}Traffic Monitoring Menu${COLOR_NC}           "
        echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
        echo -e " ${COLOR_GREEN}[1]${COLOR_NC} • Monitor Real-time Traffic"
        echo -e " ${COLOR_GREEN}[2]${COLOR_NC} • Show Traffic History"
        echo -e " ${COLOR_GREEN}[3]${COLOR_NC} • Export Traffic Stats"
        echo -e " ${COLOR_GREEN}[0]${COLOR_NC} • Back to Main Menu"
        echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
        
        read -p "Select option [0-3]: " option
        
        case $option in
            1) 
                monitor_traffic
                read -p "Press enter to continue..."
                ;;
            2) 
                show_traffic_history
                read -p "Press enter to continue..."
                ;;
            3)
                export_traffic_stats
                ;;
            0) 
                break
                ;;
            *)
                echo -e "${COLOR_RED}Invalid option${COLOR_NC}"
                sleep 1
                ;;
        esac
    done
}

# Export traffic statistics
export_traffic_stats() {
    local export_file="/etc/AutoscvpnMantap/export/traffic_$(date +%Y%m%d_%H%M%S).csv"
    
    # Create export directory if it doesn't exist
    mkdir -p /etc/AutoscvpnMantap/export
    
    # Create CSV header
    echo "Timestamp,Protocol,Connections,Bandwidth" > $export_file
    
    # Add data
    while read -r line; do
        timestamp=$(echo $line | cut -d'[' -f2 | cut -d']' -f1)
        for proto in vless vmess trojan; do
            connections=$(echo $line | grep -o "\[$proto: [^]]*" | cut -d' ' -f2)
            bandwidth=$(echo $line | grep -o "\[$proto: [^]]*" | cut -d' ' -f4)
            echo "$timestamp,$proto,$connections,$bandwidth" >> $export_file
        done
    done < "/etc/AutoscvpnMantap/logs/traffic_stats.log"
    
    echo -e "${COLOR_GREEN}Traffic statistics exported to: $export_file${COLOR_NC}"
    sleep 2
}

# Export functions
export -f monitor_traffic
export -f show_traffic_history
export -f show_traffic_menu
export -f export_traffic_stats