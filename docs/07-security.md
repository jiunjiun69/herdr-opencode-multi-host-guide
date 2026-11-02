# 07｜公開 GitHub 前的去識別化與安全檢查

## 本倉庫刻意不包含

- 任何真實內網／外網 IP、網域、主機別名、SSH 帳號、工號或個人工作路徑。
- SSH 私鑰、公鑰實體內容、`authorized_keys`、`known_hosts`、SSH Config 個人檔案。
- API Key、憑證、Token、`.env` 或其他金鑰檔。
- 實際 LiteLLM／MCP Gateway URL、模型私有代號、專案名稱與識別碼。
- 內部 Git Repository、服務架構圖、Log、CLI 錯誤中含真實資產的畫面。

所有公開範例使用 `devuser`、`ubuntu-01`、`192.0.2.10`、`gateway.example.com` 等保留值。

## Git 提交前檢查

```bash
# 在倉庫根目錄

git status --short
git diff --cached --stat

git grep -n -E 'PRIVATE KEY|BEGIN RSA|BEGIN OPENSSH|api[_-]?key|token|password' -- ':!docs/07-security.md' || true
```

上面的 `git grep` 僅能輔助檢查；不能取代人工審查。請逐一檢查 staged diff、檔案名稱與提交歷史，包含所有範例 JSON、PowerShell、圖片及隱藏檔。Git commit 歷史中曾經提交的秘密，之後刪掉檔案也不能當作從歷史中移除。

## 機密已外洩時

優先停用／輪替憑證與金鑰；不要只刪除公開檔案。若涉及組織資產，依當地資訊安全事件程序處理。

## SSH、安全與權限

- 只在**明確授權**的主機部署公鑰或 Herdr Server。
- 第一個 `ssh` 連線須核對 Host Key 指紋，不使用 `StrictHostKeyChecking=no` 迴避驗證。
- 私鑰只保存在 Windows 本機，建議加 Passphrase；不要複製到遠端 Linux。
- 不需要使用 `sudo` 啟動 OpenCode Agent；把工作目錄限制在必要範圍內。
- Agent 若可透過 MCP 執行高風險寫入操作，應設置工具確認與稽核。
- 不要為了 Proxy 安裝而關閉憑證驗證，或將未審核的二進位檔放到生產主機。
- `~/.local/bin/herdr`／`~/.local/bin/opencode` 的 `chmod 755` 是執行檔權限設定，不是授予 Agent 根權限。

## 授權與版本

本教學用 MIT 授權，不表示 Herdr／OpenCode 本身是 MIT。它們的軟體授權需各自查看上游倉庫。此處僅提供使用指南與自己的輔助腳本。
