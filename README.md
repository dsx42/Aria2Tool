# Aria2Tool 简介

* 提高 Aria2 使用体验的小工具：集成封装 Aria2 和 AriaNg 项目
* 提供优化的 Aria2 的配置
* 自动更新 BT 下载使用的 Tracker
* 支持 Windows 10/11、OpenWrt 23.05.5、x86_64 架构的 Linux，如 Debian 12.8.0

# 下载

## Windows 10/11

从如下链接下载最新的版本：`Aria2Tool_v2025.1.4.zip`

> https://github.com/dsx42/Aria2Tool/releases

## x86_64 Linux

系统需要支持 `systemd`，且需要预先安装如下软件：

* `ca-certificates`：HTTPS 支持
* `wget`：发起网络请求
* `zip`：解压缩

从如下链接下载最新的版本：`aria2-x86_64-linux_v2025.1.4.zip`

> https://github.com/dsx42/Aria2Tool/releases

```bash
wget -p '/opt' 'https://github.com/dsx42/Aria2Tool/releases/download/v2025.1.4/aria2-x86_64-linux_v2025.1.4.zip'
```

## OpenWrt 23.05.5

从如下链接下载最新的版本：`aria2_tool_openwrt.sh`

> https://github.com/dsx42/Aria2Tool/releases

```bash
wget -O /aria2_tool_openwrt.sh 'https://github.com/dsx42/Aria2Tool/releases/download/v2025.1.4/aria2_tool_openwrt.sh'
```

# 如何使用本工具？

## Windows 10/11

解压下载好的压缩包，双击解压后的 `Aria2Tool.cmd`，根据提示操作即可

* Aria2 占用资源极少，推荐设为开机启动 Aria2，并且创建桌面快捷方式，使用时直接双击 `AriaNg` 快捷方式  
* 升级新版本时，先关闭 Aria2，再解压覆盖旧版本目录

## x86_64 Linux

RPC 端口为 6800，未设置 RPC 密钥，示例如下：

```bash
# 下载
wget -p /opt 'https://github.com/dsx42/Aria2Tool/releases/download/v2025.1.4/aria2-x86_64-linux_v2025.1.4.zip'
# 解压
unzip /oppt/aria2-x86_64-linux_v2025.1.4.zip -d /opt
# 安装并指定下载目录
/usr/bin/env bash /oppt/aria2/aria2_tool.sh install /mnt/usb/download
# 设为开机启动
systemctl enable aria2
# 启动 aria2
systemctl start aria2
# 更新 tracker，不会重启 aria2 进程
systemctl reload aria2
```

aria2_tool_openwrt.sh 支持如下命令：

```bash
/usr/bin/env bash aria2_tool.sh install download_dir
/usr/bin/env bash aria2_tool.sh uninstall
```

* `install`：安装 Aria2
    * `download_dir`：Aria2 保存下载文件的绝对路径，默认为该脚本所在目录下的子目录 `download/`
* `uninstall`：卸载 Aira2

aria2 通过 `systemctl` 命令管理：

```bash
# 设为开机启动
systemctl enable aria2
# 禁止开机启动
systemctl disable aria2
# 更新 tracker，不会重启 aria2 进程
systemctl reload aria2
# 重启 aria2
systemctl restart aria2
# 查看 aria2 的状态
systemctl status aria2
```

## OpenWrt 23.05.5

RPC 端口为 6800，未设置 RPC 密钥，示例如下：

```bash
# 建立 Aria2 配置文件目录
mkdir -p /etc/aria2
# 建立 Aria2 下载文件目录
mkdir -p /mnt/sda/download
# 下载 Aria2 脚本到 Aria2 配置文件目录
wget -O /etc/aria2/aria2_tool_openwrt.sh 'https://github.com/dsx42/Aria2Tool/releases/download/v2025.1.4/aria2_tool_openwrt.sh'
# 安装 Aria2，并指定下载文件目录
/bin/sh /etc/aria2/aria2_tool_openwrt.sh install '/mnt/sda/download'
# Aria2 设为开机启动
/bin/sh /etc/aria2/aria2_tool_openwrt.sh enable
# Aira2 定时自动更新 Tracker
/bin/sh /etc/aria2/aria2_tool_openwrt.sh auto_reload '/etc/aria2/aria2_tool_openwrt.sh'
# 设置 aria2 用户为下载文件目录所有者
chown -R aria2 '/mnt/sda/download'
```

aria2_tool_openwrt.sh 支持如下命令：

```bash
/bin/sh aria2_tool_openwrt.sh install download_dir download_dir_disk_type
/bin/sh aria2_tool_openwrt.sh start download_dir download_dir_disk_type
/bin/sh aria2_tool_openwrt.sh stop
/bin/sh aria2_tool_openwrt.sh status
/bin/sh aria2_tool_openwrt.sh reload
/bin/sh aria2_tool_openwrt.sh auto_reload script_file_path
/bin/sh aria2_tool_openwrt.sh enable
/bin/sh aria2_tool_openwrt.sh disable
```

* `install`：安装 Aria2
    * `download_dir`：Aria2 保存下载文件的绝对路径，默认为 `/etc/aria2/download/`
    * `download_dir_disk_type`：Aria2 保存下载文件的路径所属硬盘类型，支持如下值：
        * `HDD`：机械硬盘，默认值
        * `SSD`：固态硬盘
* `start`：启动 Aria2
    * `download_dir`：Aria2 保存下载文件的路径，默认为 `/etc/aria2/download/`
    * `download_dir_disk_type`：Aria2 保存下载文件的路径所属硬盘类型，支持如下值：
        * `HDD`：机械硬盘，默认值
        * `SSD`：固态硬盘
* `stop`：关闭 Aria2
* `status`：Aria2 状态
* `reload`：更新 Tracker，重启 Aria2
* `auto_reload`：每 4 小时自动更新 Tracker，重启 Aria2
    * `script_file_path`：本脚本的绝对路径，包含脚本名
* `enable`：Aria2 开机自动启动
* `disable`：取消 Aria2 开机动启动

# 常见问题

## 首次 BT 下载无速度或速度很慢

* 这是正常的，因为需要根据所在网络生成路由表 `dht.dat`  
* 建议首次 BT 下载使用热门的 BT 种子，即做种的人比较多的 BT 种子，提高路由表生成速度

## 非首次 BT 下载无速度或速度很慢

* BT 种子无人做种：无解，换 BT 种子
* 热门 BT 种子无速度：所在网络禁止 BT 下载，有些公司内网会限制或禁止 BT 下载，无解
* 下载速度没有迅雷快：这是正常的，迅雷有专用的下载服务器加速

# 依赖

## aria2c.exe

* 本工具使用的 `aria2c.exe` 用于提供 Windows 系统的下载能力
* 提取自 aria2 项目：https://github.com/aria2/aria2/releases

## aria2c

* 本工具使用的 `aria2c` 用于提供 Linux 系统的下载能力
* 提取自 aria2-static-build 项目：https://github.com/abcfy2/aria2-static-build/releases

## index.html

* 本工具使用的 `index.html` 用于下载任务的管理界面
* 提取自 AriaNg 项目的 AllInOne 编译产物： https://github.com/mayswind/AriaNg/releases

## AriaNg.ico

* 本工具使用的 `AriaNg.ico` 用于 `index.html` 的快捷方式图标
* 提取自 AriaNg-Native 项目的资源文件：https://github.com/mayswind/AriaNg-Native

## BT Tracker 来源

BT Tracker 从以下来源更新：

* https://github.com/ngosang/trackerslist
* https://github.com/DeSireFire/animeTrackerList
* https://github.com/XIU2/TrackersListCollection

# 参考资料

* Aria2 官方文档：https://aria2.github.io/manual/en/html/index.html
