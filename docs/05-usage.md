# 05｜Herdr 日常管理：Local、Remote、Pane、Agent

## 先確認遠端可用

**Windows PowerShell：**

```powershell
herdr status
herdr machine list
herdr machine status
herdr
```

在 Herdr TUI 左側 Machines 選取遠端主機，進入 Workspace 的 Pane，再確認：

```bash
hostname
whoami
pwd
uname -s
command -v opencode
opencode --version
```

當 `hostname` 和 `pwd` 顯示 Linux 環境，代表已操作遠端終端，而非 Windows 本機。

## 啟動第一個 Agent

```bash
mkdir -p ~/agent-lab
cd ~/agent-lab
opencode
```

在 OpenCode 裡先下**唯讀**測試任務，避免一開始就讓 Agent 修改重要目錄。

## 同時啟動第二個 Agent

在 Herdr 的同一台主機上建立另一個 Pane 或 Tab：

```bash
mkdir -p ~/agent-lab-2
cd ~/agent-lab-2
opencode
```

一個 Pane 啟動一個 OpenCode TUI，就有兩個可分別管理的工作階段。Herdr 會管理這些 Pane，整合插件可增強 Session ID 與狀態回報。多個 Agent 不會自動互通或分配工作。

如果不同 Agent 要修改同一個 Git 倉庫，建議先建立不同 Git Worktree，避免同時修改相同工作目錄。

## 常用按鍵（Herdr TUI 預設）

| 操作 | 快捷鍵 |
| --- | --- |
| 新增 Tab | `Ctrl+B`，放開後 `C` |
| 左右分割 Pane | `Ctrl+B` → `V` |
| 上下分割 Pane | `Ctrl+B` → `-` |
| 下一／上一個 Tab | `Ctrl+B` → `N`／`P` |
| Workspace 選擇 | `Ctrl+B` → `W` |
| Detach，保留背景工作 | `Ctrl+B` → `Q` |
| 快捷鍵總覽 | `Ctrl+B` → `?` |

以上為官方預設快捷鍵；若已修改設定或不同 Herdr 版本，請以 `Ctrl+B` → `?` 為準。

## Detach 與 Stop 的差異

- `Ctrl+B` → `Q`：只退出前景 TUI，Server 和 Agent 的 Pane 仍執行。
- 再輸入 `herdr`：重新附加原有工作階段。
- `herdr server stop`：**停止**該 Server 和 Pane；不要當作普通退出指令。
- 主機重新開機／服務停止後，不保證未完成的 Agent 工作能原樣繼續。Session 介面和對話恢復能力取決於整合狀態及版本。

## Windows 本機與一般 SSH 終端的區別

在 Herdr 管理的 Pane 內執行 OpenCode，Herdr 才能管理該 Pane。自己在外部 PowerShell 開 `ssh user@host` 並執行 `opencode`，不等於自動納入 Herdr 的管理清單。

## 每次新增 Ubuntu 的重複工作

1. SSH Key 已存在（Windows 只需產生一次）。
2. 每台 Ubuntu 預先授權公鑰一次（可由 IT 統一佈署）。
3. Herdr `machine add`：遠端 Herdr Binary 缺少時，提供離線 Binary。
4. 遠端若沒有 OpenCode，再安裝該 Linux CLI。
5. 在遠端建立其自訂 Provider／金鑰／MCP 設定，並安裝 Herdr OpenCode integration。
6. 在 Herdr TUI 打開遠端 Pane，執行 `opencode`。

這套流程是**集中管理**，不是將所有主機的檔案系統合併成單一工作目錄。

來源：[Herdr 工作階段](https://herdr.dev/tui/docs/persistence-remote/)｜[Connecting machines](https://herdr.dev/tui/docs/connecting-machines/)
