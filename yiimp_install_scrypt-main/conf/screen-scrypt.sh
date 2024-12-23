#!/bin/bash
 LOG_DIR=/var/log/yiimp
 WEB_DIR=/var/web
 STRATUM_DIR=/var/stratum
 USR_BIN=/usr/bin
 
 screen -dmS main bash $WEB_DIR/crons/main.sh
 screen -dmS loop2 bash $WEB_DIR/crons/loop2.sh
 screen -dmS blocks bash $WEB_DIR/crons/blocks.sh
 screen -dmS debug tail -f $LOG_DIR/debug.log
 

 
