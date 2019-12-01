#!/system/bin/sh

#PATHS
LSPEED=/data/lspeed

LOG_DIR=$LSPEED/logs
LOG=$LOG_DIR/main_log.log

echo "[$(date +"%H:%M:%S:%3N %d-%m-%Y")] Some loging started" | tee -a $LOG

chmod 777 /system/etc/lspeed/lspeed.sh
/system/etc/lspeed/lspeed.sh &

echo "[$(date +"%H:%M:%S:%3N %d-%m-%Y")] Some loging ended" | tee -a $LOG

exit 0