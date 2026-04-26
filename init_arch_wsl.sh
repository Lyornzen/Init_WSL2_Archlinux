#!/bin/bash

# --- 1. 权限与用户检测 ---
if [ "$EUID" -ne 0 ]; then 
  echo "请以 root 身份运行此脚本。"
  exit
fi

echo "========= Arch Linux WSL2 智能初始化脚本 (含 WSL 配置) ========="

# 检测是否存在非 root 用户 (UID >= 1000)
EXISTING_USER=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1; exit}' /etc/passwd)

if [ -n "$EXISTING_USER" ]; then
    USER_NAME=$EXISTING_USER
    echo "检测到已存在用户: $USER_NAME，将跳过创建步骤。"
else
    read -p "未检测到普通用户，请输入要创建的用户名: " USER_NAME
    while true; do
        read -rs -p "请输入用户密码: " USER_PWD
        echo
        read -rs -p "请再次输入密码以确认: " USER_PWD_CONFIRM
        echo
        if [ "$USER_PWD" == "$USER_PWD_CONFIRM" ]; then
            break
        else
            echo "错误：两次输入的密码不一致，请重新输入。"
        fi
    done

    # 执行创建
    useradd -m -G wheel -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$USER_PWD" | chpasswd
    echo "用户 $USER_NAME 创建成功。"
fi

# --- 2. 写入 /etc/wsl.conf 设置默认用户 ---
echo "正在配置 /etc/wsl.conf..."
cat << WSL_CONF_EOF > /etc/wsl.conf
[user]
default=$USER_NAME
WSL_CONF_EOF
echo "已设置 $USER_NAME 为 WSL 默认登录用户。"

# --- 3. 基础系统配置 (Root 阶段) ---
echo "正在配置系统底座..."
echo "nameserver 8.8.8.8" > /etc/resolv.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

if ! grep -q "archlinuxcn" /etc/pacman.conf; then
    cat << 'CN_EOF' >> /etc/pacman.conf

[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
CN_EOF
fi

# Locale 设置
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 基础包安装
pacman -Sy --noconfirm
pacman -S --noconfirm --needed archlinuxcn-keyring
pacman -S --noconfirm --needed sudo base-devel git vim bash-completion xdg-user-dirs

# 确保 wheel 组权限
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# --- 4. 切换至用户身份执行后续安装 ---
echo "-----------------------------------------------"
echo "正在以 $USER_NAME 身份配置环境..."

sudo -u "$USER_NAME" bash << USER_EOF
    cd ~
    # A. 目录创建 (KDE 规范)
    mkdir -p ~/{Desktop,Documents,Downloads,Music,Pictures,Public,Templates,Videos,Code,Build,Embedded}
    
    if [ ! -f ~/.config/user-dirs.dirs ]; then
        mkdir -p ~/.config
        cat << 'XDG_EOF' > ~/.config/user-dirs.dirs
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_MUSIC_DIR="\$HOME/Music"
XDG_PICTURES_DIR="\$HOME/Pictures"
XDG_PUBLICSHARE_DIR="\$HOME/Public"
XDG_TEMPLATES_DIR="\$HOME/Templates"
XDG_VIDEOS_DIR="\$HOME/Videos"
XDG_EOF
    fi

    # B. 安装常用工具 (Python, Paru)
    sudo pacman -S --noconfirm --needed paru python python-pip python-setuptools

    # C. 配置镜像源
    grep -q "AURURL" ~/.bashrc || echo 'export AURURL="https://aur.tuna.tsinghua.edu.cn"' >> ~/.bashrc
    
    mkdir -p ~/.config/pip
    cat << 'PIP_EOF' > ~/.config/pip/pip.conf
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
PIP_EOF
USER_EOF

# --- 5. 权限扫尾 ---
chown -R "$USER_NAME:wheel" "/home/$USER_NAME"

echo "-----------------------------------------------"
echo "配置流程结束！"
echo "已完成：用户创建、WSL 默认用户设置、KDE 目录规范、Python 及工具安装。"
echo "-----------------------------------------------"