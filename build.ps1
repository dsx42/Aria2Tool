Clear-Host

Set-Location -Path "$PSScriptRoot"

$ProductJsonPath = "$PSScriptRoot\product.json"

if (!(Test-Path -Path "$ProductJsonPath" -PathType Leaf)) {
    Write-Warning -Message ("$ProductJsonPath 不存在")
    [System.Environment]::Exit(0)
}

$ProductInfo = $null
try {
    $ProductInfo = Get-Content -Path "$ProductJsonPath" | ConvertFrom-Json
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

$ProjectName = $ProductInfo.'name'
if (!$ProjectName) {
    Write-Warning -Message ("$ProductJsonPath 不存在 name 信息")
    [System.Environment]::Exit(0)
}

$Files = $ProductInfo.'files'
if (!$Files -or $Files -isNot [System.Array] -or $Files.Count -le 0) {
    Write-Warning -Message ("$ProductJsonPath 不存在 files 信息")
    [System.Environment]::Exit(0)
}

$CopyFiles = @()
foreach ($File in $Files) {
    $CopyFiles += "$PSScriptRoot\$File"
}

$Output = 'target'
$OutputPath = "$PSScriptRoot\$Output"
$OutputProjectPath = "$OutputPath\${ProjectName}"
$OutputFileName = "${ProjectName}_v$Version"
$ZipFilePath = "$OutputPath\$OutputFileName.zip"
$Sha256FilePath = "$OutputPath\$OutputFileName.sha256"

if (Test-Path -Path "$OutputPath" -PathType Container) {
    Remove-Item -Path "$OutputPath" -Recurse -Force
}

New-Item -Path "$OutputProjectPath" -ItemType Directory -Force | Out-Null

New-Item -Path "$OutputPath\aria2" -ItemType Directory -Force | Out-Null

Copy-Item -Path $CopyFiles -Destination "$OutputProjectPath" -Force -Recurse

Copy-Item -Path "$PSScriptRoot\aria2_tool_openwrt.sh" -Destination "$OutputPath\aria2_tool_openwrt.sh" -Force

Copy-Item -Path "$PSScriptRoot\aria2_tool.sh" -Destination "$OutputPath\aria2\aria2_tool.sh" -Force
Copy-Item -Path "$PSScriptRoot\aria2c" -Destination "$OutputPath\aria2\aria2c" -Force

Compress-Archive -Path "$OutputProjectPath" -DestinationPath "$ZipFilePath" -Force

Compress-Archive -Path "$OutputPath\aria2" -DestinationPath "$OutputPath\aria2_x86_64_linux_v$Version.zip" -Force

$Hash = Get-FileHash -Path "$ZipFilePath" -Algorithm SHA256

$OpenwrtHash = Get-FileHash -Path "$OutputPath\aria2_tool_openwrt.sh" -Algorithm SHA256

$LinuxHash = Get-FileHash -Path "$OutputPath\aria2_x86_64_linux_v$Version.zip" -Algorithm SHA256

$Checksum = $Hash.Hash + " $OutputFileName.zip"
$LinuxChecksum = $LinuxHash.Hash + " aria2_x86_64_linux_v$Version.zip"
$OpenwrtChecksum = $OpenwrtHash.Hash + ' aria2_tool_openwrt.sh'

Add-Content -Path "$Sha256FilePath" -Value $Checksum
Add-Content -Path "$Sha256FilePath" -Value $LinuxChecksum
Add-Content -Path "$Sha256FilePath" -Value $OpenwrtChecksum

Write-Host -Object ''
Write-Host -Object ('Path: ' + $Hash.Path)
Write-Host -Object ''
Write-Host -Object ('SHA256: ' + $Hash.Hash)
Write-Host -Object ''
Write-Host -Object ''
Write-Host -Object ('Path: ' + $LinuxHash.Path)
Write-Host -Object ''
Write-Host -Object ('SHA256: ' + $LinuxHash.Hash)
Write-Host -Object ''
Write-Host -Object ''
Write-Host -Object ('Path: ' + $OpenwrtHash.Path)
Write-Host -Object ''
Write-Host -Object ('SHA256: ' + $OpenwrtHash.Hash)
Write-Host -Object ''
Read-Host -Prompt '按回车键关闭此窗口'
