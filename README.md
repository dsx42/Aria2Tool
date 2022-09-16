# Aria2Tool 简介

* 提高 Aria2 使用体验的小工具：集成封装 Aria2 和 AriaNg 项目
* 提供优化的 Aria2 的配置
* 可更新 BT 下载使用的 Tracker

# 下载

从如下链接下载最新的版本：`Aria2Tool_版本号.zip`

> https://github.com/dsx42/Aria2Tool/releases

# 如何使用本工具？

解压下载好的压缩包，双击解压后的 `Aria2Tool.cmd` 即可

> Aria2 占用资源极少，推荐设为开机启动 Aria2，并且创建桌面快捷方式，使用时直接双击 `AriaNg` 快捷方式  

> 升级新版本时，先关闭 Aria2，再解压覆盖旧版本目录

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
* 提取自 Aria2 项目的静态编译产物：https://github.com/q3aql/aria2-static-builds/releases

## ca-certificates.crt

* 本工具使用的 `ca-certificates.crt` 用于 HTTPS 下载
* 提取自 Aria2 项目的静态编译产物：https://github.com/q3aql/aria2-static-builds/releases

## index.html

* 本工具使用的 `index.html` 用于下载任务的管理界面
* 提取自 AriaNg 项目的 AllInOne 编译产物： https://github.com/q3aql/aria2-static-builds/releases

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
