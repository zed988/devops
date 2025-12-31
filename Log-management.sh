#!/bin/bash

#===========================
# AUTOMATED LOG MANAGEMENT SCRIPT
#===============================


LOG_DIR="/var/log"
BACKUP_DIR="/opt/log_backup"
DAYS_OLD=7
DELETE_AFTER=30
DISK_THRESHOLD=80
DATE=$(date +"%Y-%m-%d")

mkdir -p "$BACKUP_DIR"

echo "[$DATE] Log Management Started"

# Find old log files

OLD_LOGS=$(find "$OLD_DIR" -type f -name "*.log" -mtime +$DAYS_OLD 2>/dev/null)

if [ -z "$OLD_LOGS"]; then
    echo "No Logs Older then $DAYS_OLD day"
else
    for LOG in $OLD_LOGS; do 
        FILE_NAME=$(basename "$LOG")

        gzip -c "$LOG" > "$BACKUP_DIR/$FILE_NAME-$DATE.gz"
        echo "Compressed and Backed up: $LOG"

        cat /dev/null > "$LOG"

    done
fi 

#Delete Very Old Backups

find "$BACKUP_DIR" -type f -mtime +$DELETE_AFTER -exec rm -f {}\;

echo "OLD BACKUPs Cleaned"

#Disk USAGE check

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if ["$DISK_USAGE" -gt "DISK_THRESHOLD"]; then
    echo "WARNING: Disk Usage is above $DISK_THRESHOLD%"
    echo "current usage: $DISK_USAGE%"
else
    echo "Disk Usage is Health: $DISK_USAGE%"
fi

echo "[$DATE] Log MANAGEMENT Completed"
