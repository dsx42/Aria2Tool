param([switch]$StartAria2)

function RequireAdmin {
    $CurrentWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentWindowsPrincipal = New-Object -TypeName System.Security.Principal.WindowsPrincipal `
        -ArgumentList $CurrentWindowsID
    $Admin = $CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$Admin) {
        Start-Process -FilePath PowerShell.exe -ArgumentList `
            "-NoProfile -ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" $PSBoundParameters" -Verb RunAs `
            -WindowStyle Normal
        [System.Environment]::Exit(0)
    }
}

function GetVertion {
    $ProductJsonPath = "$PSScriptRoot\product.json"

    if (!(Test-Path -Path $ProductJsonPath -PathType Leaf)) {
        Write-Warning -Message ("$ProductJsonPath 不存在")
        [System.Environment]::Exit(0)
    }

    $ProductInfo = $null
    try {
        $ProductInfo = Get-Content -Path $ProductJsonPath | ConvertFrom-Json
    }
    catch {
        Write-Warning -Message ("$ProductJsonPath 解析失败")
        [System.Environment]::Exit(0)
    }
    if (!$ProductInfo -or $ProductInfo -isNot [PSCustomObject]) {
        Write-Warning -Message ("$ProductJsonPath 解析失败")
        [System.Environment]::Exit(0)
    }

    $Version = $ProductInfo.'version'
    if (!$Version) {
        Write-Warning -Message ("$ProductJsonPath 不存在 version 信息")
        [System.Environment]::Exit(0)
    }

    return $Version
}

function GetOldAria2Config {

    if (!(Test-Path -Path "$PSScriptRoot\aria2.conf" -PathType Leaf)) {
        return $null
    }

    $Config = @{}
    Get-Content -Path "$PSScriptRoot\aria2.conf" -Force | ForEach-Object {
        if (!$_) {
            return
        }
        $Values = $_.Split('=', [System.StringSplitOptions]::RemoveEmptyEntries)
        if (!$Values -or $Values.Length -lt 2) {
            return
        }

        $Key = $Values[0]
        if (!$Key) {
            return
        }

        $Value = $Values[1]
        if (!$Value) {
            return
        }

        $Config.Add($Key, $Value)
    }

    if ($Config.Count -lt 1) {
        return $null
    }

    return $Config
}

function GetDownloadPath {
    param ($OldConfig)

    # 下载目录保留用户设置的目录
    if ($OldConfig -and $OldConfig.Contains('dir')) {
        $DownloadPath = $OldConfig['dir']
        if ($DownloadPath -and (Test-Path -Path "$DownloadPath" -PathType Container)) {
            return $DownloadPath
        }
    }

    $DownloadPath = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile) + '\Downloads'
    if (Test-Path -Path "$DownloadPath" -PathType Container) {
        return $DownloadPath
    }

    return [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
}

function GetDownloadPathDiskType {
    param ($DownloadPath)

    $DownloadDriverLetter = Split-Path -Path "$DownloadPath" -Qualifier

    # 默认为 SSD
    $Disks = Get-Disk
    if (!$Disks) {
        return 'SSD'
    }

    foreach ($Disk in $DIsks) {
        if (!$Disk) {
            continue
        }
        $PhydicalDisk = Get-PhysicalDisk -FriendlyName $Disk.FriendlyName
        if (!$PhydicalDisk) {
            continue
        }
        $Partitions = Get-Partition -DiskNumber $Disk.DiskNumber
        if (!$Partitions) {
            continue
        }
        foreach ($Partition in $Partitions) {
            if (!$Partition) {
                continue
            }
            if (!$_.DriveLetter) {
                continue
            }
            if (($_.DriveLetter + ':') -ine "$DownloadDriverLetter") {
                continue
            }
            if ($PhydicalDisk.MediaType -ieq 'HDD') {
                return 'HDD'
            }
            return 'SSD'
        }
    }

    return 'SSD'
}

function WriteAria2Config {
    param($Trackers = '')

    # 获取旧配置
    $OldConfig = GetOldAria2Config

    $DownloadPath = GetDownloadPath -OldConfig $OldConfig
    $DownloadPathDiskType = GetDownloadPathDiskType -DownloadPath $DownloadPath
    $EnableMmap = 'false'
    $FileAllocation = 'none'
    if ($DownloadPathDiskType -eq 'HDD') {
        $EnableMmap = 'true'
        $FileAllocation = 'falloc'
    }

    if (!$Trackers -and $OldConfig -and $OldConfig.Contains('bt-tracker')) {
        $Trackers = $OldConfig['bt-tracker']
        if (!$Trackers) {
            $Trackers = ''
        }
    }

    # 磁盘内存缓存最大 1024M，最小 16M
    $DiskCache = 16
    $AvailableMBytes = (Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory).AvailableMBytes
    if ($AvailableMBytes -gt (1024 * 4)) {
        $DiskCache = 1024
    }
    elseif ($AvailableMBytes -gt (512 * 4)) {
        $DiskCache = 512
    }
    elseif ($AvailableMBytes -gt (256 * 4)) {
        $DiskCache = 256
    }
    elseif ($AvailableMBytes -gt (128 * 4)) {
        $DiskCache = 128
    }
    elseif ($AvailableMBytes -gt (64 * 4)) {
        $DiskCache = 64
    }
    elseif ($AvailableMBytes -gt (32 * 4)) {
        $DiskCache = 32
    }

    $Aria2Config = [ordered]@{
        'dir'                              = "$DownloadPath";
        'input-file'                       = "$PSScriptRoot\aria2.session";
        'log'                              = "$PSScriptRoot\aria2.log";
        'max-concurrent-downloads'         = '50';
        'continue'                         = 'true';
        'connect-timeout'                  = '10';
        'max-connection-per-server'        = '16';
        'max-file-not-found'               = '10';
        'max-tries'                        = '0';
        'min-split-size'                   = '4M';
        'netrc-path'                       = "$PSScriptRoot\.netrc";
        'retry-wait'                       = '10';
        'server-stat-of'                   = "$PSScriptRoot\server.status";
        'server-stat-if'                   = "$PSScriptRoot\server.status";
        'split'                            = '16';
        'stream-piece-selector'            = 'geom';
        'timeout'                          = '10';
        'ca-certificate'                   = "$PSScriptRoot\ca-certificates.crt";
        'http-accept-gzip'                 = 'true';
        'load-cookies'                     = "$PSScriptRoot\cookies.sqlite";
        'save-cookies'                     = "$PSScriptRoot\cookies.sqlite";
        'user-agent'                       = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36';
        'bt-detach-seed-only'              = 'true';
        'bt-enable-lpd'                    = 'true';
        'bt-force-encryption'              = 'true';
        'bt-load-saved-metadata'           = 'true';
        'bt-max-peers'                     = '128';
        'bt-min-crypto-level'              = 'arc4';
        'bt-prioritize-piece'              = 'head';
        'bt-remove-unselected-file'        = 'true';
        'bt-require-crypto'                = 'true';
        'bt-request-peer-speed-limit'      = '5';
        'bt-save-metadata'                 = 'true';
        'bt-tracker'                       = "$Trackers";
        'bt-tracker-connect-timeout'       = '10';
        'bt-tracker-timeout'               = '10';
        'dht-entry-point'                  = 'dht.transmissionbt.com:6881';
        'dht-entry-point6'                 = 'dht.transmissionbt.com:6881';
        'dht-file-path'                    = "$PSScriptRoot\dht.dat";
        'dht-file-path6'                   = "$PSScriptRoot\dht6.dat";
        'dht-listen-port'                  = '51413';
        'enable-dht6'                      = 'true';
        'follow-torrent'                   = 'false';
        'listen-port'                      = '51413';
        'enable-rpc'                       = 'true';
        'rpc-allow-origin-all'             = 'true';
        'rpc-listen-all'                   = 'true';
        'rpc-max-request-size'             = '10M';
        'allow-piece-length-change'        = 'true';
        'always-resume'                    = 'false';
        'auto-save-interval'               = '20';
        'conf-path'                        = "$PSScriptRoot\aria2.conf";
        'content-disposition-default-utf8' = 'true';
        'daemon'                           = 'true';
        'disk-cache'                       = "${DiskCache}M";
        'enable-mmap'                      = "$EnableMmap";
        'file-allocation'                  = "$FileAllocation";
        'save-not-found'                   = 'false';
        'log-level'                        = 'warn';
        'summary-interval'                 = '0';
        'save-session'                     = "$PSScriptRoot\aria2.session";
        'save-session-interval'            = '20'
    }

    if (Test-Path -Path "$PSScriptRoot\aria2.conf" -PathType Leaf) {
        Remove-Item -Path "$PSScriptRoot\aria2.conf" -Force
    }
    if (!(Test-Path -Path "$PSScriptRoot\aria2.session" -PathType Leaf)) {
        New-Item -Path "$PSScriptRoot\aria2.session" -ItemType File -Force | Out-Null
    }
    if (Test-Path -Path "$PSScriptRoot\aria2.log" -PathType Leaf) {
        $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
        if (!$Aria2Process) {
            Remove-Item -Path "$PSScriptRoot\aria2.log" -Force
        }
    }
    if (!(Test-Path -Path "$PSScriptRoot\server.status" -PathType Leaf)) {
        New-Item -Path "$PSScriptRoot\server.status" -ItemType File -Force | Out-Null
    }
    if (!(Test-Path -Path "$PSScriptRoot\cookies.sqlite" -PathType Leaf)) {
        New-Item -Path "$PSScriptRoot\cookies.sqlite" -ItemType File -Force | Out-Null
    }

    $ConfigArray = @()
    $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    foreach ($Config in $Aria2Config.GetEnumerator()) {
        $ConfigArray += ($Config.Key + '=' + $Config.Value)
    }

    [System.IO.File]::WriteAllLines("$PSScriptRoot\aria2.conf", $ConfigArray, $Utf8NoBomEncoding)
}

function GetTrackers {

    $GithubProxy = 'https://ghproxy.com'

    $UrlArray = @(
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best_ip.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_best.txt',
        'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/best.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ip.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ip.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_https.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_https.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_ws.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_ws.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_http.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_http.txt',
        'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/http.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all_udp.txt',
        'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt',
        'https://raw.githubusercontent.com/DeSireFire/animeTrackerList/master/AT_all.txt',
        'https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/all.txt'
    )

    $TotalTracker = 0;
    $RepeatTracker = 0;
    $ExistTrackers = @{}
    $TrackerArray = @()

    foreach ($Url in $UrlArray) {
        Write-Host -Object ''
        Write-Host -Object "Tracker 来源: $Url"
        $Content = $null
        try {
            $Content = Invoke-RestMethod -Method Get -Uri "$Url" -TimeoutSec 1
        }
        catch {
            $Content = $null
        }
        if ([System.String]::IsNullOrEmpty($Content)) {
            try {
                $Content = Invoke-RestMethod -Method Get -Uri "$GithubProxy/$Url" -TimeoutSec 3
            }
            catch {
                $Content = $null
            }
            if ([System.String]::IsNullOrEmpty($Content)) {
                Write-Host -Object "Tracker 来源: $Url 请求失败" -ForegroundColor Red
                continue
            }
        }

        $ContentArray = $Content.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($null -eq $ContentArray -or $ContentArray.Length -le 0) {
            Write-Host -Object "Tracker 来源: $Url 无可用 Tracker 返回" -ForegroundColor Red
            continue
        }

        foreach ($Str in $ContentArray) {
            if ([System.String]::IsNullOrEmpty($Str)) {
                continue
            }

            $StrArray = $Str.Replace('udp://', ',udp://').Replace('http://', ',http://').Replace('https://', `
                    ',https://').Replace('wss://', ',wss://').Replace('ws://', ',ws://').Split(',', [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($null -eq $StrArray -or $StrArray.Length -le 0) {
                continue
            }

            foreach ($StrTracker in $StrArray) {
                $TrackerStr = $StrTracker.Trim().Replace(' ', '').Replace("`t", '').Replace("`r", `
                        '').Replace('announce"', 'announce').Replace('announce+', 'announce').Replace('announce-', `
                        'announce')
                if ([System.String]::IsNullOrEmpty($TrackerStr)) {
                    continue
                }
                if (!$TrackerStr.EndsWith('announce') -and !$TrackerStr.EndsWith('announce.php')) {
                    Write-Host -Object "Tracker $TrackerStr 不是 announce 或 announce.php 结尾" -ForegroundColor Yellow
                }

                $TotalTracker = $TotalTracker + 1
                if ($ExistTrackers.ContainsKey($TrackerStr)) {
                    $RepeatTracker = $RepeatTracker + 1
                    continue
                }

                $ExistTrackers.Add($TrackerStr, 1)
                $TrackerArray += $TrackerStr
            }
        }
    }

    Write-Host -Object ''
    Write-Host -Object ("总 Tracker 数: $TotalTracker, 重复 Tracker 数: $RepeatTracker, 可用 Tracker 数: " `
            + "$($TrackerArray.Length)") -ForegroundColor Green

    if ($TrackerArray.Length -le 0) {
        return ''
    }

    return [System.String]::Join(',', $TrackerArray)
}

function SaveSession {

    $Params = @{
        'jsonrpc' = '2.0';
        'id'      = 'Aria2Tool';
        'method'  = 'aria2.saveSession'
    }

    $Response = $null
    try {
        $Response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:6800/jsonrpc' -TimeoutSec 1 `
            -Body (ConvertTo-Json -InputObject $Params) -ContentType 'application/json'
    }
    catch {
        Write-Host -Object ''
        if ($_) {
            Write-Host -Object "$_" -ForegroundColor Red
        }
        $Response = $null
    }
    if (!$Response -or !$Response.result -or $Response.result -ine 'OK') {
        Write-Host -Object ''
        Write-Host -Object '调用 aria2.saveSession 失败' -ForegroundColor Red
        return
    }

    Write-Host -Object ''
    Write-Host -Object '调用 aria2.saveSession 成功' -ForegroundColor Green
}

function Shutdown {

    $Params = @{
        'jsonrpc' = '2.0';
        'id'      = 'Aria2Tool';
        'method'  = 'aria2.shutdown'
    }

    $Response = $null
    try {
        $Response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:6800/jsonrpc' -TimeoutSec 1 `
            -Body (ConvertTo-Json -InputObject $Params) -ContentType 'application/json'
    }
    catch {
        Write-Host -Object ''
        if ($_) {
            Write-Host -Object "$_" -ForegroundColor Red
        }
        $Response = $null
    }
    if (!$Response -or !$Response.result -or $Response.result -ine 'OK') {
        Write-Host -Object ''
        Write-Host -Object '调用 aria2.shutdown 失败' -ForegroundColor Red
        return
    }

    Write-Host -Object ''
    Write-Host -Object '调用 aria2.shutdown 成功' -ForegroundColor Green
}

function ForceShutdown {

    $Params = @{
        'jsonrpc' = '2.0';
        'id'      = 'Aria2Tool';
        'method'  = 'aria2.forceShutdown'
    }

    $Response = $null
    try {
        $Response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:6800/jsonrpc' -TimeoutSec 1 `
            -Body (ConvertTo-Json -InputObject $Params) -ContentType 'application/json'
    }
    catch {
        Write-Host -Object ''
        if ($_) {
            Write-Host -Object "$_" -ForegroundColor Red
        }
        $Response = $null
    }
    if (!$Response -or !$Response.result -or $Response.result -ine 'OK') {
        Write-Host -Object ''
        Write-Host -Object '调用 aria2.forceShutdown 失败' -ForegroundColor Red
        return
    }

    Write-Host -Object ''
    Write-Host -Object '调用 aria2.forceShutdown 成功' -ForegroundColor Green
}

function UpdateTracker {

    Clear-Host

    $Trackers = GetTrackers
    if (!$Trackers) {
        Write-Host -Object ''
        Write-Host -Object '未发现可用 Tracker, 更新 Tracker 失败' -ForegroundColor Red
        return
    }

    WriteAria2Config -Trackers $Trackers

    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if (!$Aria2Process) {
        Write-Host -Object ''
        Write-Host -Object 'Aria2 未启动, 更新 Tracker 失败' -ForegroundColor Red
        return
    }

    $Params = @{
        'jsonrpc' = '2.0';
        'id'      = 'Aria2Tool';
        'method'  = 'aria2.changeGlobalOption';
        'params'  = @(@{
                'bt-tracker' = "$Trackers"
            })
    }

    $Response = $null
    try {
        $Response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:6800/jsonrpc' -TimeoutSec 1 `
            -Body (ConvertTo-Json -InputObject $Params) -ContentType 'application/json'
    }
    catch {
        Write-Host -Object ''
        if ($_) {
            Write-Host -Object "$_" -ForegroundColor Red
        }
        $Response = $null
    }
    if (!$Response -or !$Response.result -or $Response.result -ine 'OK') {
        Write-Host -Object ''
        Write-Host -Object '更新 Tracker 失败' -ForegroundColor Red
        SaveSession
        return
    }

    SaveSession
    Write-Host -Object ''
    Write-Host -Object '更新 Tracker 成功' -ForegroundColor Green
}

function StartAria2 {

    Clear-Host

    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if ($Aria2Process) {
        SaveSession
        Write-Host -Object ''
        Write-Host -Object 'Aria2 运行中' -ForegroundColor Green
        return
    }

    WriteAria2Config -Trackers (GetTrackers)

    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if ($Aria2Process) {
        SaveSession
        Write-Host -Object ''
        Write-Host -Object 'Aria2 运行中' -ForegroundColor Green
        return
    }

    Start-Process -FilePath "$PSScriptRoot\aria2c.exe" -ArgumentList "--conf-path=$PSScriptRoot\aria2.conf" `
        -WorkingDirectory "$PSScriptRoot" -WindowStyle Hidden

    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if ($Aria2Process) {
        Write-Host -Object ''
        Write-Host -Object 'Aria2 启动成功' -ForegroundColor Green
        return
    }

    Write-Host -Object ''
    Write-Host -Object 'Aria2 启动失败' -ForegroundColor Red
}

function StopAria2 {

    Clear-Host

    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if (!$Aria2Process) {
        Write-Host -Object ''
        Write-Host -Object 'Aria2 未启动' -ForegroundColor Green
        return
    }

    SaveSession
    Shutdown

    $RetryCount = 1
    while ($true) {
        $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
        if (!$Aria2Process) {
            Write-Host -Object ''
            Write-Host -Object 'Aria2 关闭成功' -ForegroundColor Green
            return
        }
        $RetryCount = $RetryCount + 1
        Start-Sleep -Seconds 3
        if ($RetryCount -gt 10) {
            ForceShutdown
            Start-Sleep -Seconds 3
            $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
            if (!$Aria2Process) {
                Write-Host -Object ''
                Write-Host -Object 'Aria2 强制关闭成功' -ForegroundColor Yellow
                return
            }
            Stop-Process -InputObject $Aria2Process -Force
            Write-Host -Object ''
            Write-Host -Object '强杀 Aria2 进程' -ForegroundColor Red
            return
        }
    }
}

function CreateShortcut {
    param ([switch]$Desktop)

    Clear-Host

    $TargetPath1 = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Programs) + '\Aria2Tool.lnk'
    $TargetPath2 = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Programs) + '\AriaNg.lnk'
    if ($Desktop) {
        $TargetPath1 = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop) + '\Aria2Tool.lnk'
        $TargetPath2 = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop) + '\AriaNg.lnk'
    }

    if (Test-Path -Path "$TargetPath1" -PathType Leaf) {
        Remove-Item -Path "$TargetPath1" -Force
    }
    if (Test-Path -Path "$TargetPath2" -PathType Leaf) {
        Remove-Item -Path "$TargetPath2" -Force
    }

    $WScriptShell = New-Object -ComObject 'WScript.Shell'
    $Shortcut1 = $WScriptShell.CreateShortcut("$TargetPath1")
    $Shortcut1.TargetPath = "$PSScriptRoot\Aria2Tool.cmd"
    $Shortcut1.WindowStyle = 1
    $Shortcut1.WorkingDirectory = "$PSScriptRoot"
    $Shortcut1.Save()

    $Shortcut2 = $WScriptShell.CreateShortcut("$TargetPath2")
    $Shortcut2.TargetPath = "$PSScriptRoot\index.html"
    $Shortcut2.WindowStyle = 1
    $Shortcut2.IconLocation = "$PSScriptRoot\AriaNg.ico"
    $Shortcut2.WorkingDirectory = "$PSScriptRoot"
    $Shortcut2.Save()

    Write-Host -Object ''
    if ($Desktop) {
        Write-Host -Object '桌面快捷方式创建完成' -ForegroundColor Green
        return
    }

    Write-Host -Object '开始菜单快捷方式创建完成' -ForegroundColor Green
}

function AutoStart {
    param ([switch]$Enabled)

    Clear-Host

    $TargetPath = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Startup) + '\AutoStartAria2.js'
    if (!$Enabled) {
        if (Test-Path -Path "$TargetPath" -PathType Leaf) {
            Remove-Item -Path "$TargetPath" -Force
        }
        Write-Host -Object ''
        Write-Host -Object '删除开机启动下载服务 Aria2 成功' -ForegroundColor Green
        return
    }

    if (Test-Path -Path "$TargetPath" -PathType Leaf) {
        Remove-Item -Path "$TargetPath" -Force
    }

    $FilePath = "`"$PSScriptRoot\Aria2Tool.ps1`"".Replace('\', '\\')

    $Utf8NoBomEncoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false

    [System.IO.File]::WriteAllLines("$TargetPath", ("new ActiveXObject('Shell.Application')." `
                + "ShellExecute('PowerShell', '-NoProfile -ExecutionPolicy RemoteSigned -File $FilePath " `
                + "-StartAria2', null, null, 0);"), $Utf8NoBomEncoding)

    Write-Host -Object ''
    Write-Host -Object '下载服务 Aria2 成功设为开机启动' -ForegroundColor Green
}

function MainMenu {

    Clear-Host

    $Options = [ordered]@{
        '1' = '启动下载服务 Aria2';
        '2' = '关闭下载服务 Aria2';
        '3' = '查看当前下载服务 Aria2 状态';
        '4' = '打开下载管理界面 AriaNg';
        '5' = 'BT 下载加速';
        '6' = '创建桌面快捷方式';
        '7' = '创建开始菜单快捷方式';
        '8' = '开机启动下载服务 Aria2';
        '9' = '删除开机启动下载服务 Aria2';
        'q' = '退出'
    }

    Write-Host -Object ''
    Write-Host -Object "=====> Aria2Tool v$VersionInfo https://github.com/dsx42/Aria2Tool <====="
    Write-Host -Object ''
    Write-Host -Object '======================================================'
    $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
    if ($Aria2Process) {
        Write-Host -Object "请选择要进行的操作: Aria2 运行中 ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))" `
            -ForegroundColor Green
    }
    else {
        Write-Host -Object "请选择要进行的操作: Aria2 未启动 ($((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))" `
            -ForegroundColor Red
    }
    Write-Host -Object '======================================================'
    foreach ($Option in $Options.GetEnumerator()) {
        Write-Host -Object ''
        Write-Host -Object ($Option.Key + ': ' + $Option.Value)
    }

    $InputOption = 'q'
    while ($true) {
        Write-Host -Object ''
        $InputOption = Read-Host -Prompt '请输入选择的序号，按回车键确认'
        if ($null -eq $InputOption -or '' -eq $InputOption) {
            Write-Host -Object ''
            Write-Warning -Message '选择无效，请重新输入'
            continue
        }
        if ($Options.Contains($InputOption)) {
            break
        }
        Write-Host -Object ''
        Write-Warning -Message '选择无效，请重新输入'
    }

    if ('q' -eq $InputOption) {
        [System.Environment]::Exit(0)
    }
    if ('1' -eq $InputOption) {
        StartAria2
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('2' -eq $InputOption) {
        StopAria2
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('3' -eq $InputOption) {
        $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
        if ($Aria2Process) {
            SaveSession
        }
        MainMenu
    }
    if ('4' -eq $InputOption) {
        $Aria2Process = Get-Process -Name 'aria2c' -ErrorAction SilentlyContinue
        if ($Aria2Process) {
            SaveSession
        }
        Start-Process -FilePath "$PSScriptRoot/index.html"
        MainMenu
    }
    if ('5' -eq $InputOption) {
        UpdateTracker
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('6' -eq $InputOption) {
        CreateShortcut -Desktop
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('7' -eq $InputOption) {
        CreateShortcut
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('8' -eq $InputOption) {
        AutoStart -Enabled
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
    if ('9' -eq $InputOption) {
        AutoStart
        Write-Host -Object ''
        Read-Host -Prompt '按确认键返回主菜单'
        MainMenu
    }
}

$VersionInfo = GetVertion

if ($Version) {
    return $VersionInfo
}

#RequireAdmin

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'
$Host.UI.RawUI.WindowTitle = "Aria2Tool v$VersionInfo"
Set-Location -Path "$PSScriptRoot"

if ($StartAria2) {
    StartAria2
}
else {
    MainMenu
}
