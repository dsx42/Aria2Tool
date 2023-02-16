# Aria2Tool 简介

* 提高 Aria2 使用体验的小工具：集成封装 Aria2 和 AriaNg 项目
* 提供优化的 Aria2 的配置
* 自动更新 BT 下载使用的 Tracker
* 支持 Windows 10/11 和 OpenWrt 22.03.3

# 下载

## Windows 10/11

从如下链接下载最新的版本：`Aria2Tool_v2023.2.16.zip`

> https://github.com/dsx42/Aria2Tool/releases

## OpenWrt 22.03

从如下链接下载最新的版本：`aria2_tool_openwrt.sh`

> https://github.com/dsx42/Aria2Tool/releases

```bash
wget -O /aria2_tool_openwrt.sh 'https://github.com/dsx42/Aria2Tool/releases/download/v2023.2.16/aria2_tool_openwrt.sh'
```

# 如何使用本工具？

## Windows 10/11

解压下载好的压缩包，双击解压后的 `Aria2Tool.cmd` 即可

> Aria2 占用资源极少，推荐设为开机启动 Aria2，并且创建桌面快捷方式，使用时直接双击 `AriaNg` 快捷方式  

> 升级新版本时，先关闭 Aria2，再解压覆盖旧版本目录

## OpenWrt 22.03

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

* 本工具使用的 `aria2c.exe` 用于提供下载能力
* 提取自 Aria2 项目：https://github.com/aria2/aria2/releases

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
