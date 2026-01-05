#!/bin/bash
# ==================
# Live Thret Detection & Response with Bash
# ==================


# ------ CONFIG ---------
SSH_LOG="/var/log/auth.log"
ALERT_LOG="/var/log/threat_alert.log"
FAILED_THRESHOLD=5
CHECK_INTERVAL=5
BLOCKED_IPS_FILE="/tmp/blocked_ips.list"

mkdir -p /tmp
touch "$ALERT_LOG" "$BLOCKED_IPS_FILE"

# ----------- FUNCTIONS-------------
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}
alert() {
    echo "[ALERT] $(timestamp) - $1" | tee -a "$ALERT_LOG"
}
block_ip() {
    IP="$1"

    if grep -q "$IP" "$BLOCKED_IPS_FILE"; then
        return
    fi 

    iptables -A INPUT -s "$IP" -j DROP
    echo "$IP" >> "$BLOCKED_IPS_FILE"
    alert "IP BLOCKED: $IP"
}
check_ssh_bruteforce() {
    grep "FAILED Password" "$SSH_LOG" 2>/dev/null \
    | awk '{print $(NF-3)' \
    | sort \
    | uniq -c \
    | while read COUNT IP; do 
        if [ "$COUNT" -ge "$FAILED_THRESHOLD" ]; then 
            alert "SSH BRUTE FORCE DETECTED FROM $IP ($COUNT)"
            block_ip "$IP"
        fi 
    done 
}

check_high_cpu() {
    ps aux --sort=%cpu |awk 'NR>1 && $3>80 {print $2, $11, $3}' \
    | while read PID CMD CPU; do
        alert "HIGH CPU MESSAGE: PID=$PID CMD=$CMD CPU=$CPU"
       done
}

check_suspicious_ports() {
    netstat -tunlp 2>/dev/null | grep -E "(:4444| :5555| :6666)" \
    | while read line; do 
        alert "Suspicious port activity: $line"
    done 
}

check_file_integrity() {
    BASELINE="/tmp/passwd.bash"

    if [ ! -f "$BASELINE" ]; then 
        sha256sum /etc/passwd > "$BASELINE" 
        alert "BASELINE CREATE FOR /etc/passwd"
    else 
        sha256sum -c "$BASELINE" >/dev/null 2>&1 || alert "FILE INTEGRITY ALERT: /etc/passwd modified"
    fi 
}

#------------ Start ------------
clear 
echo "========================================="
echo " LIVE CYBER THREAT DETECTION & RESPONSE "
echo " BASH-BASED ACTIVE DEFENSE SYSTEM "
echo "========================================="
echo "Monitoring started at $(timestamp)"
echo 

alert "Threat Monitoring Engine Started"

#--------- MAIN LOOP-------------
while true; do 
    check_ssh_bruteforce 
    check_high_cpu 
    check_suspicious_ports
    check_file_integrity
    sleep "$CHECK_INTERVAL"
done 




















