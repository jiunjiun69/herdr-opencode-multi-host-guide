#Requires -Version 5.1
<#
.SYNOPSIS
    產生（或沿用）Windows 使用者的 Herdr SSH Ed25519 Key。
.DESCRIPTION
    不會覆蓋既有 Key、不變更 Windows ssh-agent 服務狀態。
    請確認組織政策允許使用 SSH 公鑰認證。
.EXAMPLE
    .\scripts\Initialize-HerdrSsh.ps1
#>
[CmdletBinding()]
param(
    [string]$KeyPath = (Join-Path (Join-Path $HOME '.ssh') 'id_ed25519_herdr')
)

$sshDir = Split-Path -Parent $KeyPath
if (-not (Test-Path -LiteralPath $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$keygen = Join-Path $env:WINDIR 'System32\OpenSSH\ssh-keygen.exe'
if (-not (Test-Path -LiteralPath $keygen)) {
    throw "找不到 Windows OpenSSH ssh-keygen：$keygen"
}

$publicKey = "$KeyPath.pub"
if ((Test-Path -LiteralPath $KeyPath) -or (Test-Path -LiteralPath $publicKey)) {
    if ((Test-Path -LiteralPath $KeyPath) -and (Test-Path -LiteralPath $publicKey)) {
        Write-Host 'SSH Key 已存在，沿用現有金鑰，不進行覆寫。' -ForegroundColor Green
    } else {
        throw '目前只存在私鑰或公鑰其中一個檔案，請先檢查，不可直接覆寫。'
    }
} else {
    Write-Host '建立 Ed25519 Key；建議設定 Passphrase。' -ForegroundColor Yellow
    & $keygen -t ed25519 -a 64 -f $KeyPath -C 'herdr-client'
    if ($LASTEXITCODE -ne 0) {
        throw 'ssh-keygen 建立金鑰失敗。'
    }
}

if (-not (Test-Path -LiteralPath $KeyPath) -or -not (Test-Path -LiteralPath $publicKey)) {
    throw '找不到完整 SSH Key Pair。'
}

Write-Host '初始化完成。下次請使用 Add-HerdrHost.ps1 將公鑰授權到目標主機。' -ForegroundColor Green
Write-Host "Private Key: $KeyPath"
Write-Host "Public Key : $publicKey"
Write-Host '私鑰不可上傳至 GitHub、聊天訊息或遠端主機。'
Write-Host '若 Key 設有 Passphrase，Windows ssh-agent 可選擇性使用。'
