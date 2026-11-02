# 01｜Windows 手動安裝 Herdr TUI

## 適用情境

Windows 無法直接執行官網的線上安裝腳本（例如網路代理、防火牆或軟體政策限制），但能透過經核准的管道取得官方 GitHub Release。

## 1. 下載並解壓

進入 [官方 Releases](https://github.com/herdrdev/herdr/releases)，選擇與架構相符的 `herdr-windows-x86_64.zip`。本指南示範 v0.9.5。建議先核對來源、版本與組織軟體安裝政策。

將 ZIP 解壓到，例如：

```text
D:\tools\herdr\
  herdr.exe
  (壓縮檔內其他必要執行檔／ConPTY 元件)
```

**不要只抽出 `herdr.exe`**；官方 Windows ZIP 還包含本機 ConPTY Runtime，必須保留解壓目錄內容。

## 2. 加入 PATH

可透過 Windows「環境變數 → 使用者 Path」加入 `D:\tools\herdr`。重新開啟 PowerShell 後驗證：

```powershell
where.exe herdr                 # PowerShell 的 where 是 Where-Object 別名，請用 where.exe
(Get-Command herdr).Source
herdr --version
herdr --help
herdr status
```

預期可看見與下載版本相符的 `herdr --version`。`herdr status` 中 Server 為 `running` 且 Client／Server 相容時表示本機端正常。

## 3. 開啟及退出

```powershell
herdr
```

在 TUI 中依序按 `Ctrl+B`、放開後按 `Q`，**Detach** 客戶端但保留背景工作階段。下次執行 `herdr` 可回到原工作階段。

只有確定要終止該 Server 和所屬 Pane／Agent 時，才執行：

```powershell
herdr server stop
```

## 4. TUI 與 Herdr App 不同

`herdr-windows-x86_64.zip` 是 **Herdr TUI**。Herdr Desktop App／Core 是另一套 Runtime，不共用 Session。本指南只介紹 TUI，不要混用 Desktop 安裝方式與 `hc` 指令。

## 5. 重要提醒

- 在公司限制環境，版本更新可能無法在線上完成，可手動取得新的官方 ZIP（先停止／規劃既有工作階段的維護窗口）。
- 遠端主機也需要自己的 Herdr Server；只安裝 Windows 本機是不夠的。
- 不應把 Herdr 管理用 socket、Log 或包含主機資訊的設定檔上傳到公開 GitHub。

來源：[Herdr 安裝](https://herdr.dev/tui/docs/install/)｜[Windows 支援](https://herdr.dev/tui/docs/windows-beta/)
