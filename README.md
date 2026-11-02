# Herdr × OpenCode V2：Windows 與多台 Linux Agent 管理指南

> 繁體中文實作筆記｜Windows Herdr TUI → SSH → Ubuntu Herdr Server → OpenCode V2 → OpenAI-compatible LLM Gateway
>
> **範例已去識別化**：不包含任何真實內網 IP、使用者名稱、主機名稱、API Key、憑證或工作目錄。請只在已獲授權的主機上操作。

## 這個倉庫能幫你做什麼？

在一台 Windows 電腦上使用 **Herdr TUI** 集中管理本機與多台 Ubuntu 的終端機、Workspace、Tab、Pane 與 OpenCode Agent。遠端主機各自執行 Herdr Server 和 OpenCode CLI；LLM 可使用統一的 OpenAI-compatible Gateway，不必每台都部署模型。

```text
Windows / Windows Terminal
└─ Herdr TUI (local session)
   ├─ Local: OpenCode Agent A / Agent B
   ├─ ubuntu-01 (SSH)
   │  └─ Herdr Server → OpenCode CLI → LLM Gateway
   └─ ubuntu-02 (SSH)
      └─ Herdr Server → OpenCode CLI → LLM Gateway
```

**Herdr 管理 Agent ≠ Agent 會自動互相協作。** 初階用法是自己分派任務、集中檢視狀態；多 Agent 修改同一份程式碼時，建議使用各自的 Git Worktree。

**本指南主線是 Herdr TUI**（Windows 上執行 `herdr`），不是另一套 Herdr Desktop App／Core。兩者的 Runtime／Session 不共用，不要混用兩套安裝指令。

## 對應版本與環境

| 元件 | 本指南實作版本／範圍 |
| --- | --- |
| Herdr TUI | v0.9.5（範例版本；升級後請重新核對官方文件） |
| OpenCode CLI | V2.2.5（實作範例） |
| Windows | PowerShell 5.1+、OpenSSH、可執行 `ssh` / `scp` |
| 遠端 Linux | Ubuntu 24.04 x86_64（其他 Linux 請依平台選資產） |
| LLM | OpenAI-compatible Gateway（範例不依賴特定供應商） |

## 最短路徑：首次建立

1. [Windows 端安裝 Herdr TUI](docs/01-windows-herdr.md)：下載官方 ZIP、解壓、PATH、確認 CLI。
2. [一次性設定 SSH Key](docs/02-ssh-and-hosts.md)：產生 Key；選擇性設定 `ssh-agent`；授權第一台主機。
3. [遠端離線部署 Herdr](docs/03-herdr-offline.md)：先下載 `herdr-linux-x86_64`，用 `HERDR_REMOTE_BINARY` 避免遠端 Proxy 下載失敗。
4. [安裝遠端 OpenCode V2](docs/04-opencode-remote.md)：Windows 下載 tar.gz → SCP → Ubuntu `~/.local/bin` → 自訂模型設定 → Herdr integration。
5. [實際使用與快捷鍵](docs/05-usage.md)：多主機／多 Pane／退出、重連與常用診斷。
6. [故障排除](docs/06-troubleshooting.md) 與 [公開前安全清單](docs/07-security.md)。
7. [如何建立公開 GitHub 倉庫並推送](docs/08-publish.md)。

### 第一次設定 SSH Key

```powershell
# Windows PowerShell
.\scripts\Initialize-HerdrSsh.ps1
```

### 新增第一台主機（首次需要部署公鑰）

```powershell
# 範例名稱／位址均為虛構，請換成已授權的主機。
.\scripts\Add-HerdrHost.ps1 `
  -Target 'devuser@192.0.2.10' `
  -Label 'ubuntu-01' `
  -AuthorizeKey `
  -RemoteBinary 'D:\tools\herdr\herdr-linux-x86_64'
```

首次會要求 SSH 密碼與 Herdr 遠端安裝確認（必要時）。`192.0.2.10` 是文件保留用示例 IP，**不是可連接的主機**。

### 後續已授權的主機

```powershell
.\scripts\Add-HerdrHost.ps1 `
  -Target 'devuser@192.0.2.20' `
  -Label 'ubuntu-02' `
  -RemoteBinary 'D:\tools\herdr\herdr-linux-x86_64'
```

> 只有當新主機已授權該 SSH 公鑰時，才能省略 `-AuthorizeKey`。腳本不會繞過主機指紋檢查，也不會略過遠端 Herdr 安裝。

### 驗證

```powershell
herdr status
herdr machine list
herdr machine status
herdr
```

在 Herdr 左側 Machines 選到遠端 Ubuntu 的 Pane 後：

```bash
hostname
whoami
pwd
command -v opencode
opencode --version
opencode models
opencode
```

## 倉庫內容

```text
.
├── README.md
├── docs/
│   ├── 01-windows-herdr.md
│   ├── 02-ssh-and-hosts.md
│   ├── 03-herdr-offline.md
│   ├── 04-opencode-remote.md
│   ├── 05-usage.md
│   ├── 06-troubleshooting.md
│   ├── 07-security.md
│   └── 08-publish.md
├── scripts/
│   ├── Initialize-HerdrSsh.ps1
│   ├── Add-HerdrHost.ps1
│   └── install-opencode-linux.sh
├── examples/
│   ├── opencode.json.example
│   └── ssh-config.example
├── .gitignore
└── LICENSE
```

## 注意事項

- **原生安裝 OpenCode CLI** 適合讓 Herdr 操作遠端既有工作目錄；Docker 則適合有嚴格環境隔離需求，但需額外管理 Volume、權限、工具與容器生命週期。
- **SSH Key 不是萬能通行證**：每台新主機仍需一次授權公鑰（或由授權的管理工具統一佈署），再安裝／偵測相容的 Herdr Server。
- **不應發佈實際設定檔**：範例僅有 `opencode.json.example`；API Key 務必保存在本機私有檔案或憑證管理系統中。
- 建議在低權限測試帳號、沒有敏感資料的目錄試跑。若要進行工具呼叫或寫入操作，請先確認模型 Gateway、權限及稽核政策。
- 手動 ZIP / binary 安裝的更新流程，要對照當前官方發行版，不要盲目執行一鍵更新。

## 官方參考

- [Herdr TUI 安裝](https://herdr.dev/tui/docs/install/)
- [Herdr 多主機管理](https://herdr.dev/tui/docs/connecting-machines/)
- [Herdr Remote / HERDR_REMOTE_BINARY](https://herdr.dev/tui/docs/persistence-remote/)
- [Herdr Windows 支援](https://herdr.dev/tui/docs/windows-beta/)
- [Herdr OpenCode 整合](https://herdr.dev/tui/docs/integrations/)
- [Herdr v0.9.5 Release](https://github.com/herdrdev/herdr/releases/tag/v0.9.5)
- [OpenCode V2 CLI / Standalone](https://opencode.ai/v2/docs)
- [OpenCode V2 Provider 設定](https://opencode.ai/v2/docs/providers)
- [OpenCode V2 設定檔](https://opencode.ai/v2/docs/config)

## 授權

教學與腳本以 [MIT License](LICENSE) 發布。本倉庫**不是** Herdr 或 OpenCode 官方專案，第三方軟體的授權另以各官方倉庫為準。
