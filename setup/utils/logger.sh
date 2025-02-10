#!/bin/bash
# AutoscvpnMantap Logger
# Created: 2025-02-09 12:00:29 UTC
# Author: Defebs-vpn

LOG_DIR="/etc/AutoscvpnMantap/logs"
CURRENT_DATE=$(date -u +"%Y-%m-%d %H:%M:%S")
CURRENT_USER="Defebs-vpn"

log_action() {
    local action=$1
    local details=$2
    echo "[$CURRENT_DATE UTC] [$CURRENT_USER] $action: $details" >> "$LOG_DIR/system.log"
}

log_installation() {
    echo "[$CURRENT_DATE UTC] [$CURRENT_USER] New installation started" > "$LOG_DIR/install.log"
}

log_error() {
    echo "[$CURRENT_DATE UTC] [$CURRENT_USER] ERROR: $1" >> "$LOG_DIR/error.log"
}