# 04｜在 Ubuntu 原生安裝 OpenCode V2 並接入 LLM Gateway

## 原生安裝還是 Docker？

本指南推薦 **OpenCode V2 CLI 原生安裝於 `~/.local/bin`**。如此 Herdr Pane 中啟動的 OpenCode 可以直接使用該 Linux 帳號授權的檔案、Git、編譯器及 SSH 工具。

Docker 另有隔離優點，但需要規劃工作目錄 Volume、UID/GID、Network、MCP 工具與生命週期。若安全政策要求隔離，才改用經審查的容器方案，不要直接對容器掛整個主機根目錄或 Docker Socket。

## 1. 下載對應 Linux Standalone

從 [OpenCode V2 官方文檔](https://opencode.ai/v2/docs) 取得與 Ubuntu x86_64 / glibc 相容的 Standalone CLI。假設官方下載資產已由核准來源存成：

```text
D:\tools\opencode\opencode-linux-x64.tar.gz
```

請根據實際資產名稱調整；不是所有發行版都使用相同檔名。可先檢查壓縮檔與來源。

## 2. 從 Windows 上傳

**以下在 Windows PowerShell 執行，不是在 Ubuntu Shell：**

```powershell
scp 'D:\tools\opencode\opencode-linux-x64.tar.gz' ubuntu-01:~/
```

## 3. 在 Ubuntu 解壓安裝

**以下在 Herdr 的 Ubuntu Terminal 執行：**

```bash
tar -tzf ~/opencode-linux-x64.tar.gz  # 應看到 opencode
mkdir -p ~/.local/bin
tar -xzf ~/opencode-linux-x64.tar.gz -C ~/.local/bin opencode
chmod 755 ~/.local/bin/opencode
~/.local/bin/opencode --version
```

或使用倉庫的腳本：

```bash
bash scripts/install-opencode-linux.sh ~/opencode-linux-x64.tar.gz
```

如果腳本是從 Windows 取得，請先將它複製到 Ubuntu；上面命令的 `scripts/` 路徑以「已在 Ubuntu 複製／clone 本倉庫」為前提。

`chmod 755` 是對 **`opencode` 檔案** 設定「擁有者 rwx、其他使用者 r-x」，不是將 Shell 或整個目錄授權給所有人寫入。

```bash
export PATH="$HOME/.local/bin:$PATH"
grep -Fqx 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
  printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
command -v opencode
opencode --version
```

## 4. 建立 Linux 設定（不可直接複製 Windows 路徑）

```bash
mkdir -p ~/.config/opencode
chmod 700 ~/.config/opencode
nano ~/.config/opencode/opencode.json
```

複製 [examples/opencode.json.example](../examples/opencode.json.example) 的內容；把 `https://gateway.example.com/v1`、模型 ID 換成自己的**經授權**端點與模型。實際端點可能不是 `/v1`，請依 Gateway API 路由為準。

金鑰不要寫進可公開的 JSON。示範使用：

```json
"apiKey": "{file:~/.config/opencode/litellm-key.txt}"
```

若必要，從 Windows 使用已授權的管道傳送金鑰；以下範例必須在 **Windows PowerShell** 執行：

```powershell
scp "$HOME\.config\opencode\litellm-key.txt" ubuntu-01:~/.config/opencode/litellm-key.txt
```

不要在 Linux Terminal 貼 Windows 的 `C:\Users\...` 路徑，那裡的 `scp` 會把 `C:` 當成 SSH 主機名稱。也不要把金鑰貼到聊天室、GitHub Issue 或公開倉庫中。

Ubuntu 設定權限：

```bash
chmod 600 ~/.config/opencode/opencode.json
chmod 600 ~/.config/opencode/litellm-key.txt
test -s ~/.config/opencode/litellm-key.txt && echo API_KEY_FILE_OK
```

## 5. 驗證設定與推論

```bash
python3 -m json.tool ~/.config/opencode/opencode.json >/dev/null && echo JSON_OK
opencode debug config   # 顯示載入設定的來源；不必公開完整輸出
opencode reload
opencode models | grep '^examplegateway/'
```

預期範例：

```text
examplegateway/demo-coder
```

如果仍只列出預設外部模型：先檢查 `~/.config/opencode/opencode.json` 是否真的存在、JSON 格式、`providers`（V2 複數）、`settings.baseURL` 是否仍為占位文字、模型 ID 與金鑰路徑。`models` 出現僅證明設定被讀取，**不是**推論成功證明。

實際測試：

```bash
mkdir -p ~/agent-lab
cd ~/agent-lab
opencode run --model examplegateway/demo-coder '請只回答 OK，不要執行任何工具。'
```

`examplegateway/demo-coder` 是占位模型；請以實際 `opencode models` 顯示的模型代替。確認能完成推論才算 Gateway 連線成功。

## 6. 安裝 Herdr OpenCode 整合

先備份設定（若存在），然後在 **Ubuntu** 執行：

```bash
if [ -d ~/.config/opencode ]; then
  cp -a ~/.config/opencode "$HOME/.config/opencode.backup.$(date +%Y%m%d%H%M%S)"
fi
~/.local/bin/herdr integration status
~/.local/bin/herdr integration install opencode
~/.local/bin/herdr integration status
```

Herdr 0.9.5 整合可在 OpenCode 設定目錄建立插件檔，支援 V2 Pane 的 Session／狀態回報。**重新啟動 OpenCode TUI** 才會載入新插件。

## 7. MCP 遷移注意

- Windows `.exe`、`.venv/Scripts/python.exe` 與瀏覽器路徑，不能原封不動拿到 Linux 使用。
- 本機 MCP（stdio）需在各自 Linux 主機部署依賴；遠端 HTTP MCP 則依網路、權限與政策設定。
- 先確保最小的模型推論成功，再逐一啟用 MCP；對具寫入權限的 MCP 工具使用確認模式。
- 不要把實際 API Key、內網位址、專案識別碼、主機名寫入此公開範例。

來源：[OpenCode V2](https://opencode.ai/v2/docs)｜[Providers](https://opencode.ai/v2/docs/providers)｜[Config](https://opencode.ai/v2/docs/config)｜[Herdr integrations](https://herdr.dev/tui/docs/integrations/)
