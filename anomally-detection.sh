#!/bin/bash

#================
# Proactive Anomaly Detector
#================

LOG_FILE="/var/log/anomaly_detector.log"
STATE_DIR="/tmp/anomaly_state"
INTERVAL=5          # Seconds between checks
THRESHOLD_CPU=80    #%
THRESHOLD_MEM=85    #%
THRESHOLD_LOAD=2.0  #per core
THRESHOLD_DISK=80   #%

mdkir -p "$STATE_DIR"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}
log() {
    echo "[$(timestamp)] $1" | tee -a "LOG_FILE"
}

# ----------------------------
# METRIC COLLECTORS
# ----------------------------
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}'
}
get_mem_usage() {
    free | awk '/MEM:/ {printf "%.0f", $3/$2*100}'
}
get_load_per_core() {
    CORES=$(nproc)
    LOAD=$(awk '{print $1}' /proc/loadavg)
    awk "BEGIN {print $LOAD / $CORES}"
}
get_disk_usage() {
    df / | awk 'NR==2 {gsub("%", ""); print $5}'
}

#-----------------
#ANOMALY CHECKS
#-----------------
check_threshold() {
    local METRIC=$1
    local VALUE=$2
    local LIMIT=$3

    awk "BEGIN {exit !($VALUE > $LIMIT)}"

}
#======================
# automated Response
#=======================

respond() {
    local ISSUE=$1
    log "ANOMALY DETECTED: $ISSUE"
    # EXAMPLE actions (pick your poison)
    # systemctl restart nginx
    # pkill -f runaway_process
    # notify-send "system anomaly" "$ISSUE"
    echo "$ISSUE" > "$STATE_DIR/last_alert"
}

#-----------------------------
# MAIN LOOP
#------------------------------

log "starting proactive anomaly detection"
while true; do 
    CPU=$(get_cpu_usage)
    MEM=$(get_mem_usage)
    LOAD=$(get_load_per_core)
    DISK=$(get_disk_usage)

    log "Metrics | CPU: ${CPU}% MEM: ${MEM}% LOAD/core:  ${LOAD} DISK: ${DISK}%"

    check_threshold CPU "$CPU" "THRESHOLD_CPU" && respond  "High CPU Usage: ${CPU}%"
    check_threshold MEM "$MEM" "$THRESHOLD_MEM" && respond  "High Memory Usage: ${MEM}%"
    check_threshold LOAD "$LOAD" "$THRESHOLD_LOAD" && respond "abnormal load average: ${LOAD}"
    check_threshold DISK "$DISK" "$THRESHOLD_DISK" && respond "Disk usage critical: ${DISK}%"
    sleep "$INTERVAL"
    done   


















