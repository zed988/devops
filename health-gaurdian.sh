# ============================================================
# HEALTH GUARDIAN
# Production-Grade Server Monitoring & Auto-Recovery Script
#
# This script is intentionally written as a SINGLE FILE to
# demonstrate how real DevOps engineers think in Bash.
#
# What this script does:
# - Continuously evaluates server health (CPU, RAM, Disk)
# - Detects crashed or unhealthy system services
# - Restarts services safely with stateful rate-limiting
# - Scans logs for critical failure patterns
# - Records every action for audit and post-mortem analysis
#
# What this script does NOT do:
# - It does not rely on dashboards or agents
# - It does not assume perfect systems
# - It does not blindly restart services in a loop
#
# This is not a tutorial script.
# This is infrastructure logic written to survive failure.
#
# If you understand this file, you understand real DevOps Bash.
# ============================================================

#!/bin/bash

set -euo pipefail

############
#CONFIGURATION
##############

CPU_LIMIT=85
MEM_LIMIT=80
DISK_LIMIT=85

SERVICE=("nginx" "docker")

LOG_FILE=(
    "/var/log/syslog"
    "/var/log/nginx/error.log"
)

STATE_FILE="/tmp/health_guardian_restart.db"
REPORT_FILE="/var/log/health_Guardian.log"

MAX_RESTARTS=3
RESTART_WINDOW=300 #Second

##################################
# UTILITY FUNCTIONS
##################################

log(){
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$REPORT_FILE"

}

###################################
#METERICS COLLECTION
####################################

get_cpu_usage(){
    top -bn1 | awk '/Cpu/ {print int(100-$8)}'
}

get_mem_Usage(){
    free | awk '/Mem/ {print int($3/$2)*100}'
}

get_disk_usage(){
    df / | awk 'NR==2 {gsub("%",""); print $5}'
}

#SERVICE RESTART PROTECTION (STATEFULL)

can_restart() {
    service=$1
    now=$(date +%s)
    [! -f "$STATE_FILE"] && return 0
    entries=$(grep "^$service:" "$STATE_FILE" 2>/dev/null || true)
    count=$(echo "$entries" | wc -l)
    last=$(echo "$entries" | tail -1 | cut -d: f2)

    if ["$count" -ge "$MAX_RESTARTS"] && [ $((now -last)) -lt "$RESTART_WINDOW"]; then
        return 1
    fi
        return 0
}

record_restart(){
    echo "$1:$(date +%s)" >> "$STATE_FILE"
}

check_services(){
    for svc in "${SERVICES[@]}"; do 
        if ! systemctl is-active --quiet "$svc"; then
            if can_restart "$svc"; then 
                log "service $svc is DOWN. Restarting.."
                systemctl restart "$svc"
                record_restart "$svc"
            else 
                log "Service $svc restart BLOCKED (rate limit Exceeded)."
            fi 
        else 
            log "Service $svc is running normally."
        fi 
    done 
}
#######################
#LOG ANOMALY DETECTION
#######################

scan_logs(){
    for file in "${LOG_FILES[@]}"; do
        [ ! -f "$file" ] && continue

        hits=$(tail -n 200 "$file" | grep -Ei "Panic|fatal|segmentation|oom" || true)
            if [ -n "$hits"]; then
                log "CRITICAL log Pattern Detected in $file"
                echo "$hits" >> "$REPORT_FILE"
            fi 
    done 
}

#########################
#MAIN EXECUTION
########################

touch "$STATE_FILE" "$REPORT_FILE"

CPU=$(get_cpu_usage)
MEM=$(get_mem_Usage)
DISK=$(get_disk_usage)

log "CPU USAGE: $CPU%"
log "Memmory Usage: $MEM%"
log "Disk Usage: $DISK%"

[ "$CPU" -ge "$CPU_LIMIT" ] && log "WARNING: CPU usage above Threshold"
[ "$MEM" -ge "$MEM_LIMIT" ] && log "WARNING: Memmory usage above Threshold"
[ "$DISK" -ge "$DISK_LIMIT"] && log "WARNING: Disk Usage Above Threshold"


check_services
scan_logs

log "Health Guardian Execution Completed"
echo "--------------------------------" >> "$REPORT_FILE"





###all done. -> THANKS FOR WATCHING" #############
