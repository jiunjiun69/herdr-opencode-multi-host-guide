# 08｜公開 GitHub 倉庫建立與首次推送

此倉庫內容已使用文件保留 IP、虛構帳號和示範模型，**不代表可以跳過本機人工審查**。公開之前請先看 [公開安全檢查](07-security.md)。

## A. GitHub 網站建立空倉庫（不需 GitHub CLI）

1. 登入 GitHub，開啟 <https://github.com/new>。
2. Repository name 填入：`herdr-opencode-multi-host-guide`。
3. Visibility 選 **Public**。
4. **不要**勾選初始化 README、.gitignore 或 License（ZIP 內已經包含），建立**空倉庫**。
5. 在 Windows 將下載的 ZIP 解壓，進入內部資料夾 `herdr-opencode-multi-host-guide`。

從該資料夾開啟 PowerShell：

```powershell
# 確認目前目錄包含 README.md、docs、scripts、examples
git status 2>$null

git init -b main
git add .
git diff --cached --stat

# 首次提交前務必檢查 staged 檔案是否包含秘密
git commit -m 'docs: add public Herdr and OpenCode multi-host guide'

git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/herdr-opencode-multi-host-guide.git
git push -u origin main
```

請將 `<YOUR_GITHUB_USERNAME>` 改成自己的 GitHub 使用者名稱。若 `git init -b main` 因 Git 版本過舊不支援，改用 `git init` 然後 `git branch -M main`。

GitHub 認證可能要求透過 Credential Manager、瀏覽器或 PAT。**不要把 Token 貼進 Git Remote URL、README 或 PowerShell 歷史命令**。

## B. 已安裝 GitHub CLI 的簡化做法

若已經安裝且登入 `gh`，可以在倉庫資料夾執行：

```powershell
git init -b main
git add .
git diff --cached --stat
git commit -m 'docs: add public Herdr and OpenCode multi-host guide'
gh repo create herdr-opencode-multi-host-guide --public --source . --remote origin --push
```

這條指令會建立**公開**倉庫；只有在你已確認要公開且檢查完所有檔案後才執行。

## C. 日後修改

```powershell
git status
git add .
git diff --cached --stat
git commit -m 'docs: refine troubleshooting guide'
git push
```

## D. 避免出錯

- 若 GitHub 建立倉庫時已初始化 README／License，遠端會有不同初始 commit，不要強制 `git push --force`；先拉取或改建空倉庫。
- 推送前最好再檢查一次 `git diff --cached` 的實際內容；不要只看檔名。
- 見到 `remote origin already exists`，先檢查 `git remote -v` 是否指向正確倉庫，而不是盲目覆寫。
- 已推送的秘密要立即輪替；只在後續 commit 刪除檔案仍保留於舊的 Git 歷史。
