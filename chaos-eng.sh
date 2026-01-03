#Problem/Solution 
#"Imagine your system is running smoothly, then suddenly... 
#chaos. Not the bad kind, but the kind you *designed*.
# We're building a 'Chaos Engineering' Bash script that deliberately 
# breaks things in your DevOps environment. 
# This isn't about fixing problems after they happen, 
# it's about finding weaknesses *before* they impact your users, 
# ensuring your systems are truly resilient and recovery-ready."


#!/bin/bash

#chaos Engineering Resillience Script


set -euo pipefail

#---Configuration----
TARGET_PROCESS="nginx"
TARGET_PORT=80
LOG_FILE="chaos_experiments.log"

log_event(){
    echo "$(date '+%Y-%m-%d %H:%M:%S')-[CHAOS] $1" | tee -a "$LOG_FILE"
}

#CHAOs EXPERIMENTS----

#1. Kill a critical process (Simulates Process Crash)
kill_process(){
    log_event "injecting Failure: Killing Process '$TARGET_PROCESS'..."
    pkill -9 "$TARGET_PROCESS" || echo "Process Not Running."
}

#2. Network Latency (Simulates Slow or Congested Network)
inject_latency(){
    log_envent "injecting Failure: Adding 500ms Network Latency to Eth0..."
    #Requires 'iproute2' Package
    sudo tc qdisc add dev eth0 root netem delay 500ms
    sleep 30
    sudo tc qdisc del dev eth0 root netem
    log_event "Network Latency Cleared."
}

#3. Disk Stress (Simulates full Disk/I/O wait)
stress_disk(){
    log_event "Injecting Failure: Filling Disk Space Temporarily..."
    dd if=/dev/zero of=/tmp/chaos_file bs=1G count=1
    sleep 20
    rm /tmp/chaos_file
    log_event "Disk Space Cleared"
}

#4. blackhole Port (Simulates Firewall Failure/Security Group Issue)
block_port(){
    log_event "Injecting Faulure: Blocking Traffic on port $TARGET_PORT..."
    sudo iptables -A INPUT -p tcp --dport "$TARGET_PORT" -j DROP
    sleep 30
    sudo iptables -D INPUT -p tcp --dport "$TARGET_PORT" -J DROP
    log_event "Port $TARGET_PORT unblocked"
}

##EXECUTION LOGIC:---

echo "Select Chaos Experiment:"
echo "1) Kill Process"
echo "2) Network Latency"
echo "3) Disk Stress"
echo "4) Block Network Port"

read -p "Enter choice[1-4]:" Choice

case $choice in  
1) Kill_process;;
2) inject_latency;;
3) stress_disk;;
4) block_port;;
*) echo "invalid selection"; exhit 1;;
esac
log_event "Experiment Completed... Observe Monitoring Dashboards for Recovery:"
