#!/bin/bash
# 自动清理脚本：删除 7 天以前的备份包，并记录删除明细
set -e

BACKUP_DIR=/home/ubuntu/backup

echo "===== $(date '+%F %T') 开始清理 =====" >> $BACKUP_DIR/clean.log
find $BACKUP_DIR -name "backup-*.tar.gz" -mtime +7 -print -delete >> $BACKUP_DIR/clean.log
