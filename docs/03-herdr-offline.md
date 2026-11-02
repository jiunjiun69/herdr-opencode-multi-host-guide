# 03｜Proxy／離線環境部署遠端 Herdr Server

## 症狀

SSH Key、Host Alias 都成功，但執行：

```powershell
herdr machine add ubuntu-01 --label ubuntu-01
```

可能看到：

```text
matching herdr 0.9.5 is not installed on ubuntu-01 ... for linux-x86_64.
Install ... to "$HOME/.local/bin/herdr"? [Y/n] Y
error: failed to fetch update manifest: exit code: 28; machine was not saved
```

`28` 通常是 curl 連線逾時，最常見的原因是遠端主機無法直接連到下載站、代理設定或網路政策限制。這不是 SSH Key 認證失敗。

## 方案 A：官方 HERDR_REMOTE_BINARY（推薦）

1. 使用經核准的網路方式，自 [Herdr v0.9.5 Releases](https://github.com/herdrdev/herdr/releases/tag/v0.9.5) 取得 **`herdr-linux-x86_64`**（原生執行檔，非 Windows ZIP；不同 CPU 請選對應資產）。
2. 存放於 Windows，例如 `D:\tools\herdr\herdr-linux-x86_64`。
3. 在 PowerShell 執行：

```powershell
$env:HERDR_REMOTE_BINARY = 'D:\tools\herdr\herdr-linux-x86_64'
Test-Path $env:HERDR_REMOTE_BINARY   # True
herdr machine add ubuntu-01 --label ubuntu-01
```

同意安裝後，預期訊息：

```text
Saved SSH machine <machine-id>. Remote server is ready.
Open Herdr clients connect automatically.
```

`<machine-id>` 是 Herdr 自行產生的識別值，不需要手動填入。

使用自動腳本時可直接給 `-RemoteBinary` 參數，腳本會暫時指定 `HERDR_REMOTE_BINARY`，完成後還原原先的環境變數。

## 方案 B：手動 SCP（備援）

如果方案 A 因版本限制或其他原因無法部署，先在 Windows PowerShell 執行：

```powershell
ssh ubuntu-01 'mkdir -p ~/.local/bin'
scp 'D:\tools\herdr\herdr-linux-x86_64' ubuntu-01:~/.local/bin/herdr
ssh ubuntu-01 'chmod 755 ~/.local/bin/herdr'
ssh ubuntu-01 '~/.local/bin/herdr --version'
herdr machine add ubuntu-01 --label ubuntu-01
```

Windows／Ubuntu 都建議確認為相容的 Herdr 版本（此範例為 0.9.5）。

## 看到 PATH 警告怎麼辦？

```text
installed remote binary to ~/.local/bin/herdr,
but the remote shell does not resolve `herdr` to that path
```

若後續依然出現 `Remote server is ready`、`machine status` 為 `reachable`，表示主機部署已成功；只是某些遠端 Shell 的 PATH 尚未包含 `~/.local/bin`。

驗證：

```powershell
herdr machine list
herdr machine status
ssh ubuntu-01 '~/.local/bin/herdr --version'
ssh ubuntu-01 'command -v herdr || echo "Herdr not in PATH"'
```

如果經常要在 Ubuntu Shell 直接輸入 `herdr`，可在遠端 Bash 設定中加入：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**注意**：非互動式 SSH Shell 不一定讀取 `.bashrc`，這不是用 `export` 後就能保證所有遠端命令都生效。對自動化使用完整執行檔路徑通常更穩定。

## 不要做的事

- 不要把本機的 Windows `herdr.exe` 上傳到 Linux；要用 Linux 相容執行檔。
- 不要因為 Proxy 失敗就關閉 SSH 驗證、TLS 檢查或改成不可信的下載來源。
- 不要在執行中的遠端 Agent 尚未保存工作時隨意停止遠端 Herdr Server。

來源：[官方連接主機](https://herdr.dev/tui/docs/connecting-machines/)｜[遠端部署與 HERDR_REMOTE_BINARY](https://herdr.dev/tui/docs/persistence-remote/)
