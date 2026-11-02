# 06｜實際排錯紀錄與對應解法

這裡整理實作過程中的典型錯誤，全部使用虛構主機資訊。

| 錯誤／症狀 | 根因或判斷方向 | 建議處理 |
| --- | --- | --- |
| `ssh ubuntu-01` 無法解析主機 | 還沒有設定 SSH Alias；範例 `ubuntu-01` 不是 DNS 主機 | 先以 `user@IP` 驗證，再寫 `$HOME\.ssh\config` |
| `where herdr` 沒輸出 | PowerShell 的 `where` 是 `Where-Object` 別名 | 使用 `where.exe herdr` 或 `Get-Command herdr` |
| `Permission denied (publickey,password)` with `BatchMode=yes` | 禁止互動式密碼輸入，尚未有可用的 Key | 先授權公鑰，測 `ssh -o BatchMode=yes -i <key> user@host 'echo OK'` |
| `herdr machine add` 反覆要求密碼 | Herdr 需要多次 SSH，Windows SSH 連線重用能力不同 | 建議 SSH Key；檢查 Windows ssh-agent 和所用 ssh.exe |
| Git SSH 版直接認證失敗 | SSH 子程序的密碼提示／Agent 通道差異 | 先用相同 `ssh.exe` 測免互動登入；確認 PATH 順序 |
| `bash: test: too many arguments` | Windows 將遠端腳本引號處理錯誤，公鑰含空白 | 不要將多行 Bash 當成 `ssh` 命令字串；使用腳本中的 Base64 單行命令 |
| `bash: $'\r': command not found` | PowerShell 5.1 經由標準輸入傳送字串時注入 CRLF | 不使用 `$script | ssh ... bash -s` 的舊做法；改採單行命令 |
| `Public key added` 後報腳本錯誤 | 可能公鑰已寫入，只是後續 Shell 命令失敗 | 先測 `BatchMode=yes`，成功就不必重新授權 |
| `failed to fetch update manifest: exit code: 28` | 遠端下載逾時，常與 Proxy／出口規則有關 | 從 Windows 下載相容 Linux Binary，用 `HERDR_REMOTE_BINARY` |
| `remote shell does not resolve herdr` | 遠端 Shell PATH 沒有 `~/.local/bin` | 若 `Remote server is ready` + `reachable` 已成立，可以先繼續，Shell 用完整路徑 |
| Linux `scp` 複製 `C:\...` 時找不到 `c` 主機 | Windows 路徑錯誤地貼在 Ubuntu 的 Shell | Windows → Ubuntu 的 `scp` 一定在 Windows PowerShell 執行 |
| Linux `ssh ubuntu-01` 無法解析 | SSH Alias 設定只存在 Windows 使用者目錄 | Linux 並不會自動取得 Windows 的 SSH Config |
| `curl: (3) URL rejected: Port number...` | 仍使用 `GATEWAY_HOST:PORT` 占位文字 | 使用真實、授權的 Endpoint（勿公開） |
| `opencode` 找不到但 `~/.local/bin/opencode` 可執行 | 尚未設定 PATH | `export PATH="$HOME/.local/bin:$PATH"`，依使用的 Shell 持久化 |
| `/models` 看不到自訂模型 | JSON 漏貼、錯字、Provider ID、Gateway URL 錯誤或未載入 | `python3 -m json.tool`、`opencode debug config`、`opencode reload`、`opencode models` |
| `[200~mkdir: command not found` | 終端貼上時混入 Bracketed Paste 控制序列 | 清除該行重新輸入，不是套件安裝問題 |
| OpenCode integration `not installed` | 尚未在那台 Linux 安裝插件 | `~/.local/bin/herdr integration install opencode`，重啟 OpenCode |

## 排查順序：由下而上

```text
Windows SSH 是否能登入？
  ↓
ssh -o BatchMode=yes -i <key> user@host 'echo OK' 是否成功？
  ↓
SSH Config Alias 是否解析到正確主機？
  ↓
Herdr machine add 是否能完成 Server 準備？
  ↓
herdr machine status 是否 reachable？
  ↓
Ubuntu 上的 OpenCode CLI 是否安裝？
  ↓
opencode models 是否列出自訂模型？
  ↓
opencode run 是否能實際推論？
  ↓
Herdr integration 是否 current？
  ↓
Herdr Pane 的 Agent 狀態是否可追蹤？
```

## 查 Herdr 日誌

`herdr --help` 可能列出 `%APPDATA%\herdr` 的預設日誌位置，但不是每個 `.log` 都保證存在。可用 PowerShell 搜尋：

```powershell
Get-ChildItem "$env:APPDATA\herdr", "$env:LOCALAPPDATA\herdr" `
  -Recurse -File -Filter 'herdr*.log' -ErrorAction SilentlyContinue |
  Select-Object FullName, Length, LastWriteTime
```

查看日誌前注意遮蔽 Token、使用者名稱、路徑、IP、錯誤中的 Gateway URL 等資訊。

## 不能用 200 OK 代替 LLM 驗證

`curl <gateway-url>` 只是在測 HTTP 網路，回傳 401 或 404 不一定代表網路有問題；同樣 `opencode models` 列出模型，不代表真的能完成推論。務必以 `opencode run --model ...` 的實際回覆為準。

來源：[Herdr Windows](https://herdr.dev/tui/docs/windows-beta/)｜[Herdr 遠端](https://herdr.dev/tui/docs/persistence-remote/)｜[OpenCode Providers](https://opencode.ai/v2/docs/providers)
