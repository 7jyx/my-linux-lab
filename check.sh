#!/bin/bash
# 系统巡检脚本：输出当前时间、内存、磁盘
echo "===== 系统检查 ====="
date
echo "--- 内存 ---"
free -h
echo "--- 磁盘 ---"
df -h /
