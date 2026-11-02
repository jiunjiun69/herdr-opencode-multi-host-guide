#Requires -Version 5.1
<#
.SYNOPSIS
    在 Windows 將已授權的 Linux SSH 主機加入 Herdr TUI，必要時先授權公鑰。
.DESCRIPTION
    支援 Windows PowerShell 5.1；單行 Base64 遠端指令避免 CRLF / 引號問題。
    不關閉 Host Key 檢查、不傳送私鑰、不變更遠端 sshd 全域設定。
.EXAMPLE
    .\scripts\Add-HerdrHost.ps1 -Target 'devuser@192.0.2.10' -Label 'ubuntu-01' -AuthorizeKey -RemoteBinary 'D:\tools\herdr\herdr-linux-x86_64'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$')]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
    [string]$Label,

    [string]$KeyPath = (Join-Path (Join-Path $HOME '.ssh') 'id_ed25519_herdr'),

    [string]$RemoteBinary,

    [switch]$AuthorizeKey
)

# 原生 SSH 命令發生預期認證失敗時，避免將 stderr 當作 PowerShell 終止錯誤。
$ErrorActionPreference = 'Continue'

$sshExe = (Get-Command ssh.exe -ErrorAction Stop).Source
$herdrExe = (Get-Command herdr.exe -ErrorAction Stop).Source
$configPath = Join-Path (Join-Path $HOME '.ssh') 'config'
$publicKey = "$KeyPath.pub"

if (-not (Test-Path -LiteralPath $KeyPath) -or -not (Test-Path -LiteralPath $publicKey)) {
    throw '缺少 SSH Private/Public Key，請先執行 Initialize-HerdrSsh.ps1。'
}

if ($RemoteBinary -and -not (Test-Path -LiteralPath $RemoteBinary -PathType Leaf)) {
    throw "找不到遠端 Linux Herdr 安裝檔：$RemoteBinary"
}

$parts = $Target.Split('@')
$remoteUser = $parts[0]
$remoteHost = $parts[1]

Write-Host "SSH Client: $sshExe" -ForegroundColor Cyan
Write-Host "Target    : $Target" -ForegroundColor Cyan
Write-Host "Label     : $Label" -ForegroundColor Cyan

# 使用明確指定的 Key，避免誤判其他預設金鑰成功。
$check = & $sshExe -o BatchMode=yes -o IdentitiesOnly=yes -i $KeyPath $Target 'echo SSH_KEY_OK' 2>$null
$sshOk = ($LASTEXITCODE -eq 0 -and @($check) -contains 'SSH_KEY_OK')

if (-not $sshOk) {
    if (-not $AuthorizeKey) {
        throw '目標主機尚不能以指定 SSH Key 免互動登入。若有授權可使用 -AuthorizeKey 完成一次公鑰部署。'
    }

    Write-Host '尚未完成公鑰授權，請準備輸入一次 SSH 密碼。' -ForegroundColor Yellow
    $line = [System.IO.File]::ReadAllText($publicKey).Trim()
    if ($line -notmatch '^ssh-ed25519 [A-Za-z0-9+/=]+(?: .*)?$' -or $line -match '[\r\n]') {
        throw '公鑰不是預期的單行 ssh-ed25519 格式。'
    }

    # 只傳公鑰的 Base64 文字，不傳私鑰。
    # 整個遠端腳本是一條命令參數，不透過 PowerShell 管線傳入多行 Bash。
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($line + "`n"))
    $suffix = [Guid]::NewGuid().ToString('N')
    $candidate = "~/.ssh/.herdr_public_$suffix"
    $remoteCommand = "set -e; umask 077; mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; printf %s $encoded | base64 -d > $candidate; if ! grep -Fqx -f $candidate ~/.ssh/authorized_keys; then cat $candidate >> ~/.ssh/authorized_keys; fi; rm -f $candidate"

    & $sshExe -T $Target $remoteCommand
    if ($LASTEXITCODE -ne 0) {
        throw '公鑰授權失敗。請檢查 SSH 密碼、遠端 ~/.ssh 權限與 base64 工具。'
    }

    $check = & $sshExe -o BatchMode=yes -o IdentitiesOnly=yes -i $KeyPath $Target 'echo SSH_KEY_OK' 2>$null
    $sshOk = ($LASTEXITCODE -eq 0 -and @($check) -contains 'SSH_KEY_OK')
    if (-not $sshOk) {
        throw '公鑰已嘗試授權，但仍無法免互動登入。請檢查 ssh-agent、Key Passphrase 與 sshd 的 PubkeyAuthentication。'
    }
}
Write-Host 'SSH Key 驗證成功。' -ForegroundColor Green

# 為 Herdr 建立不含明碼密碼的 SSH Host Alias。
$configDir = Split-Path -Parent $configPath
if (-not (Test-Path -LiteralPath $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$hasAlias = $false
if (Test-Path -LiteralPath $configPath) {
    $aliasPattern = '^\s*Host\s+' + [regex]::Escape($Label) + '\s*$'
    $hasAlias = [bool](Select-String -LiteralPath $configPath -Pattern $aliasPattern -Quiet)
}

if (-not $hasAlias) {
    $defaultKey = Join-Path (Join-Path $HOME '.ssh') 'id_ed25519_herdr'
    if ($KeyPath -ieq $defaultKey) {
        $identity = '~/.ssh/id_ed25519_herdr'
    } else {
        $identity = $KeyPath.Replace('\', '/')
        if ($identity -match '\s') { throw '自訂 KeyPath 含有空白，請手動調整 SSH Config 的 IdentityFile 引號。' }
    }

    $entry = "`nHost $Label`n    HostName $remoteHost`n    User $remoteUser`n    Port 22`n    IdentityFile $identity`n    IdentitiesOnly yes`n"
    [System.IO.File]::AppendAllText($configPath, $entry, [System.Text.UTF8Encoding]::new($false))
    Write-Host "已新增 SSH Config Alias: $Label" -ForegroundColor Green
} else {
    Write-Host 'SSH Config 已有相同 Host Alias，將驗證其解析結果，不覆蓋既有設定。' -ForegroundColor Yellow
}

# 不只驗證連通，也確認 Alias 不會意外指向另一台主機。
$effective = & $sshExe -G $Label 2>$null
if ($LASTEXITCODE -ne 0) { throw 'SSH Config 解析失敗。' }
$effectiveHostLine = @($effective | Where-Object { $_ -match '^hostname\s+' } | Select-Object -First 1)
$effectiveUserLine = @($effective | Where-Object { $_ -match '^user\s+' } | Select-Object -First 1)
if ($effectiveHostLine.Count -ne 1 -or $effectiveUserLine.Count -ne 1) {
    throw '無法判斷 SSH Alias 的實際 HostName/User。'
}
$effectiveHost = ($effectiveHostLine[0] -replace '^hostname\s+', '').Trim()
$effectiveUser = ($effectiveUserLine[0] -replace '^user\s+', '').Trim()
if ($effectiveHost -ine $remoteHost -or $effectiveUser -ine $remoteUser) {
    throw "SSH Alias 與預期不同：$Label -> $effectiveUser@$effectiveHost。請手動檢查 SSH Config。"
}

$aliasCheck = & $sshExe -o BatchMode=yes $Label 'echo SSH_CONFIG_OK' 2>$null
if ($LASTEXITCODE -ne 0 -or @($aliasCheck) -notcontains 'SSH_CONFIG_OK') {
    throw 'SSH Alias 無法免互動登入，請確認對應 Key 與 PATH 的 ssh.exe。'
}
Write-Host 'SSH Config 驗證成功。' -ForegroundColor Green

# 官方環境變數：本機提供對應 Linux Binary，無須讓遠端即時下載更新清單。
$previousRemoteBinary = $env:HERDR_REMOTE_BINARY
try {
    if ($RemoteBinary) {
        $env:HERDR_REMOTE_BINARY = (Resolve-Path -LiteralPath $RemoteBinary).Path
        Write-Host "HERDR_REMOTE_BINARY: $env:HERDR_REMOTE_BINARY" -ForegroundColor Cyan
    }

    Write-Host '開始執行 Herdr machine add；如果遠端需要安裝會出現確認提示。' -ForegroundColor Cyan
    & $herdrExe machine add $Label --label $Label
    if ($LASTEXITCODE -ne 0) { throw 'Herdr machine add 失敗。若出現 curl exit 28，請確認 -RemoteBinary 使用正確的 Linux 資產。' }
} finally {
    if ($RemoteBinary) { $env:HERDR_REMOTE_BINARY = $previousRemoteBinary }
}

Write-Host 'Herdr 加入完成。以下列出主機狀態：' -ForegroundColor Green
& $herdrExe machine list
& $herdrExe machine status
