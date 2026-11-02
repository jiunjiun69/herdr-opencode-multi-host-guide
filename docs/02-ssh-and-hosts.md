# 02｜SSH Key 與主機快速加入

## 一次性初始化

在 **Windows PowerShell**（非 Ubuntu Shell）執行：

```powershell
.\scripts\Initialize-HerdrSsh.ps1
```

它會在 `$HOME\.ssh` 產生一組 `id_ed25519_herdr`／`id_ed25519_herdr.pub`（若存在則不覆蓋）。請為私鑰設定 Passphrase；將私鑰保留在本機且不可公開。

### 選用：Windows ssh-agent

如果 Key 有 Passphrase，希望避免反覆輸入，可在符合環境政策與管理員授權下，啟動 **Windows OpenSSH Authentication Agent**：

```powershell
# 管理員 PowerShell；依組織政策操作
Set-Service ssh-agent -StartupType Manual
Start-Service ssh-agent
```

一般 PowerShell：

```powershell
& "$env:WINDIR\System32\OpenSSH\ssh-add.exe" "$HOME\.ssh\id_ed25519_herdr"
& "$env:WINDIR\System32\OpenSSH\ssh-add.exe" -l
```

**不是強制需要 ssh-agent。** 若 Key 本來就能以 `BatchMode=yes` 成功登入，就可以直接繼續。Windows 內建 SSH agent 與 Git for Windows 的 SSH 代理不一定互通。

## 首次新增主機

先用一般 SSH 驗證並核對首次提示的主機指紋：

```powershell
ssh devuser@192.0.2.10
```

然後：

```powershell
.\scripts\Add-HerdrHost.ps1 `
  -Target 'devuser@192.0.2.10' `
  -Label 'ubuntu-01' `
  -AuthorizeKey `
  -RemoteBinary 'D:\tools\herdr\herdr-linux-x86_64'
```

上面的地址為文件專用 IP，請改成自己有權連接的主機。

流程：

1. 檢查指定的私鑰、公鑰與 Linux Binary 是否存在。
2. 用同一把 Key 測試 `ssh -o BatchMode=yes`。
3. 如果尚未授權且有 `-AuthorizeKey`，使用 **一條單行、Base64 包裝的遠端 Shell 命令** 將公鑰加入 `authorized_keys`，避免 Windows PowerShell 5.1 對多行 Bash 的 CRLF／引號破壞。可能會要求輸入 SSH 密碼。
4. 重試免互動 SSH 驗證。
5. 在 Windows `$HOME\.ssh\config` 建立 `Host` Alias，並檢查實際解析的 `hostname`、`user` 是否正確。
6. 指定 `HERDR_REMOTE_BINARY`、執行 `herdr machine add`，依提示確認遠端部署。

**函式已設計避免重複寫入相同公鑰**。若公鑰已獲授權，不會再進入授權流程。腳本不會修改 sshd 全域設定、停用 Host Key 檢查或把私鑰傳到遠端。

## 已授權的新主機

```powershell
.\scripts\Add-HerdrHost.ps1 `
  -Target 'devuser@192.0.2.20' `
  -Label 'ubuntu-02' `
  -RemoteBinary 'D:\tools\herdr\herdr-linux-x86_64'
```

若多台主機有集中管理的公鑰佈署方案，可省略 `-AuthorizeKey`。

## 核心檢查指令

```powershell
where.exe ssh
ssh -V
ssh -o BatchMode=yes ubuntu-01 'echo SSH_CONFIG_OK'
herdr machine list
herdr machine status
herdr machine reconnect ubuntu-01
```

若因 Git SSH 與 Windows OpenSSH 不同版本造成行為差異，請確認 `where.exe ssh` 中 PATH 最前面的客戶端，以及該客戶端是否能執行非互動式 SSH。可只在當前 PowerShell 視窗調整 PATH：

```powershell
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
where.exe ssh
ssh -V
```

請勿為了排查而永久變更全公司電腦的系統 PATH。

## 避免重複密碼提示

Herdr 在加入主機時需多次開 SSH 連線；Windows 不使用 Herdr 的 Unix SSH ControlSocket 重用方式。官方建議使用 SSH Key。`ssh -o BatchMode=yes ...` 成功表示已具備非互動認證，這才是決定能否穩定加入的關鍵。

## PowerShell Profile（選用）

若希望打 `Add-HerdrHost` 作為函式，將腳本以**點來源**形式載入。由於本倉庫提供的是參數化 `.ps1` 腳本，最簡單的方式是直接執行完整檔案路徑；無需修改 Profile 或放寬 ExecutionPolicy。

> 本範例不會保留任何真實主機資訊於 GitHub；實際產生的 SSH Config 僅應放在你自己的使用者目錄中。

來源：[Herdr Connecting machines](https://herdr.dev/tui/docs/connecting-machines/)｜[Windows 支援](https://herdr.dev/tui/docs/windows-beta/)
