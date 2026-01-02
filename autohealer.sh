#!/bin/bash

#---CONFIGURATION---
SERVICE="nginx"
LOG_FILE="/var/log/auto_healer.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] starting live monitoring for $SERVICE..."

#---Monitoring Loop---

while true
do
    #Check if the service is active
    if systemctl is-active --quiet $SERVICE; then
    echo "[$TIMESTAMP] $SERVICE is running perfectly."
    else
    echo "[$TIMESTAMP] Alert: $SERVICE is DOWN! Attempting to heal..." | tee -a $LOG_FILE

    #THE Healing Action
    sudo systemctl restart $SERVICE

    #Verify if healing worked
    sleep 2
        if systemctl is-active --quiet $SERVICE; then
        echo "[$TIMESTAMP] SUCCESS: $SERVICE restored." >> $LOG_FILE
        else
        echo "[$TIMESTAMP] CRITICAL: healing failed. Manual intervention needed!" >> $LOG_FILE
        fi 
    fi 


#wait 10 Second Before Next check
sleep 10
done 
