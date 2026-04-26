# Arch Linux WSL2 初始化脚本说明

## 脚本功能

* **用户与权限管理**
    * 自动检测现有非 root 用户或交互式创建新用户。
    * 配置 sudo 权限，允许 wheel 组执行管理命令。
    * 自动修改 /etc/wsl.conf，将新建或检测到的用户设为 WSL 默认登录身份。

* **系统底座配置**
    * 设置系统 Locale 为 en_US.UTF-8。
    * 配置 DNS 解析服务器为 8.8.8.8。
    * 启用 Pacman 彩色输出、并行下载（10 线程）及 ILoveCandy 进度条。

* **软件源集成**
    * 配置官方主仓库清华大学镜像源。
    * 添加 archlinuxcn 社区仓库。
    * 配置 Python PyPI 清华大学镜像源。
    * 设置 AUR (Paru) 的清华大学代理地址。

* **软件包安装**
    * 系统工具：vim, git, base-devel, bash-completion, xdg-user-dirs。
    * 开发环境：python, python-pip, python-setuptools。
    * AUR 工具：paru。

* **目录结构规范**
    * 自动创建 XDG 标准用户目录（Desktop, Downloads 等）。
    * 创建开发专用目录：Code, Build, Embedded。
    * 自动修复家目录权限，确保所有者归属于普通用户。

## 使用流程

1. 执行：在 root 环境下运行 chmod +x init_arch.sh && ./init_arch.sh。
