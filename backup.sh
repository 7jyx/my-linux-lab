#!/bin/bash
set -e
BACKUP_DIR=/root/backup
SOURCE_DIR=/root/lab
TODAY=$(date +%Y%m%d)
mkdir -p /root/backup
tar -czf $BACKUP_DIR/backup-$TODAY.tar.gz $SOURCE_DIR
echo "备份完成" >> $BACKUP_DIR/backup.log
