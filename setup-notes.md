# 从零搭一台云服务器 · 环境搭建记录

> 作者：jyx　｜　时间：2026 年 9 月
> 这份文档记录：我怎么从一台只有 Windows 的电脑开始，装好 Linux 环境、开通云主机、远程连上去，并部署第一个脚本。

---

## 1. 我做了什么

我用 **WSL2** 在自己电脑上装了 Linux（Ubuntu 24.04），又开了 **阿里云**的一台云主机（轻量应用服务器），学会了从自己电脑远程连上去、传文件、装软件、跑脚本。

## 2. 本地环境：在 Windows 上装 Linux

- **方案**：WSL2（Windows 11 家庭版）
- **系统**：Ubuntu 24.04 LTS
- **关键命令**（在管理员 PowerShell 里执行）：

  ```powershell
  wsl --install
  ```

- **踩的坑**：第一次下载 Ubuntu 时报 `Wsl/InstallDistro/0x80072f78`（服务器返回无效响应），**重试第二次就成功了**。

## 3. 云主机：开通一台服务器

| 项目 | 选择 |
|---|---|
| 产品 | 阿里云 **轻量应用服务器** |
| 配置 | **2 vCPU / 2 GiB 内存 / 40 GiB 系统盘** |
| 系统 | **Ubuntu 24.04** |
| 地域 | **华南3（广州）** |
| 时长 | 先买 **1 个月** |
| 价格 | 学生价 **¥9.90/月**（原价 ¥45，2.2 折） |

**注意事项（都是真金白银换来的）**

- 学生验证**有效期只有 30 天**，到期要重新验证（已买的产品不受影响）
- **别买年付、别开自动续费**——学生价通常只有首期便宜
- **别选 Windows 镜像**，你要练的就是 Linux
- **别买"虚拟主机/建站"类产品**，那些不给 SSH 登录，练不了

## 4. 第一次远程登录

- **命令**：

  ```bash
  ssh root@<服务器公网IP>
  ```

- 第一次连接，系统会提示 `The authenticity of host ... can't be established`，并给出对方主机的指纹，问你 `(yes/no/[fingerprint])?`
- **必须输入完整的 `yes`**，不能只打 `y`。这一步是在确认"对面真的是那台服务器"，确认后它的指纹会记进 `~/.ssh/known_hosts`，以后不再问
- 登录成功后能看到服务器的欢迎信息：系统版本、负载、磁盘使用率、内存使用率、内网 IP

## 5. 配置 SSH 免密登录

```bash
ssh-keygen -t ed25519 -C "yunwei"      # 生成一对钥匙
ssh-copy-id root@<服务器公网IP>         # 把公钥送到服务器
ssh root@<服务器公网IP>                 # 验证：这次不再问密码
```

**原理（一句话）**：一对钥匙，**私钥留在自己电脑**（`~/.ssh/id_ed25519`，绝不外传），**公钥交到服务器**（写进 `~/.ssh/authorized_keys`）；连接时服务器用公钥出一道题，只有拿着私钥的人能答对，所以不用输密码。

## 6. 传文件 + 装软件

**传文件（本地 → 服务器）：**

```bash
scp check.sh root@<服务器公网IP>:/root/
```

`scp` = secure copy，语法和 `cp` 一样，区别是目标要写成 `用户@IP:路径`。配上免密之后，它也不会再要密码。

**装软件（在服务器上）：**

```bash
sudo apt update              # 先刷新软件清单
sudo apt install -y tree     # 再安装（-y 表示自动回答"是"）
```

**为什么要加 `sudo`**：装软件要往系统目录（比如 `/usr/bin`）写文件，普通用户没有这个权限，`sudo` 就是"临时以管理员身份执行这一条命令"。

**实测数据**：这台服务器买的是 2G 内存，但 `free -h` 显示实际可用 **1.6 GiB**（剩下的被系统自己占了），已用约 450 MiB；磁盘 40G，已用 9%。**"2G 的服务器"真实体感就是这样。**

## 7. 我踩过的坑（每条都是真实经历）

| 现象 | 原因 | 怎么解决 |
|---|---|---|
| `wsl --install` 下载失败 `0x80072f78` | 网络到下载源不通 | 重试第二次成功 |
| 命令报 `command not found`，但命令名看着没错 | 粘贴带进了不可见字符（`^[[200~`） | 手打一遍；用 `history \| grep 关键词` 查看实际敲进去的内容 |
| `ls-al`、`cd/home` 报找不到命令 | 少了一个空格 | 记住格式：**命令 空格 参数** |
| `cd ~/home` 报 `No such file or directory` | 路径理解错：`~` 本身就是家目录 | 回家就是 `cd` 或 `cd ~` |
| `./hello.sh` 报 `Permission denied` | 文件没有执行权限 | `chmod +x hello.sh` |
| `./hello.sh` 报 `line 1: I: command not found` | 脚本第一行没写 `#!/bin/bash`，两句英文被当成命令执行 | 第一行加 shebang |
| `cp app.log backup/ app-0919.log` 报错 | 目标路径中间多打了一个空格 | 写成 `cp app.log backup/app-0919.log` |
| `ls` 打成 `Ii` 报 `command not found` | 小写 `l`、大写 `I`、数字 `1` 长得太像 | 敲 `ls` 时心里默念"小写 L、小写 S" |

## 8. 安全加固（2026-09-19 完成）

服务器放在公网上，一天多就被尝试猜密码 **84 次**。所以做了加固：**关闭 SSH 密码登录**，只允许密钥登录。

**操作流程（这就是运维改配置的标准动作）：**

```bash
# 1. 先看清现状
sudo grep -rin passwordauthentication /etc/ssh

# 2. 先备份（改配置前必做）
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-20260919

# 3. 编辑配置，把 PasswordAuthentication 改成 no
sudo nano /etc/ssh/sshd_config

# 4. 检查语法（没输出 = 语法正确）
sudo sshd -t

# 5. 重启服务让配置生效
sudo systemctl restart ssh

# 6. 验证一：看最终生效的配置
sudo sshd -T | grep -i passwordauthentication   # 应输出 passwordauthentication no

# 7. 验证二：模拟"只有密码的陌生人"
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@<服务器公网IP>
# 预期：Permission denied (publickey).
```

**关键经验**：动 SSH 配置前，**先确认"救援通道"可用**（云控制台的救援登录走虚拟机本地控制台，不经过 SSH），这样即使改坏了也能进去救回来。

## 9. 下一步想做什么

1. 在服务器上装 **Nginx**，让外面能访问到一个网页
2. 学**定时任务**（crontab）：自动备份 + 清理日志
3. 装 `fail2ban`，自动封掉反复尝试的 IP
4. 继续把学习记录和脚本放上来

---

## 附：关键命令清单

> 下次再搭一遍，照着这个顺序敲就行。

### 第一步 · 在 Windows 上装 Linux（管理员 PowerShell）

```powershell
wsl --install
```

### 第二步 · 从自己电脑连服务器（在 Ubuntu 里）

```bash
ssh root@<服务器公网IP>
```

### 第三步 · 配置免密登录（只需做一次）

```bash
ssh-keygen -t ed25519 -C "yunwei"
ssh-copy-id root@<服务器公网IP>
ssh root@<服务器公网IP>      # 验证：不再问密码
```

### 第四步 · 把文件传到服务器

```bash
scp check.sh root@<服务器公网IP>:/root/
```

### 第五步 · 在服务器上装软件

```bash
sudo apt update
sudo apt install -y tree
```

### 第六步 · 在服务器上跑脚本

```bash
chmod +x check.sh
./check.sh
```

### 日常检查用的四条

```bash
ls -l                    # 这里有什么、权限对不对
df -h                    # 磁盘还剩多少
free -h                  # 内存够不够
history | tail -n 60     # 我刚才干了什么
```
