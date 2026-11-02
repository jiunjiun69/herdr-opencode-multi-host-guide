#!/usr/bin/env bash
# 在 Linux 使用者目錄原生安裝 OpenCode CLI。
# 使用方式：bash scripts/install-opencode-linux.sh ~/opencode-linux-x64.tar.gz
set -euo pipefail

archive="${1:-}"
if [[ -z "$archive" || ! -f "$archive" ]]; then
  echo "Usage: bash $0 /path/to/opencode-linux-x64.tar.gz" >&2
  exit 2
fi

if ! tar -tzf "$archive" | grep -qx 'opencode'; then
  echo 'Archive does not contain an expected top-level opencode binary.' >&2
  echo 'Inspect the archive and download the matching official standalone CLI.' >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin"
if [[ -f "$HOME/.local/bin/opencode" ]]; then
  echo 'Existing opencode binary detected; stop running sessions before replacing it.' >&2
  echo 'Backup the current binary manually if you need rollback.' >&2
  exit 1
fi

tar -xzf "$archive" -C "$HOME/.local/bin" opencode
chmod 755 "$HOME/.local/bin/opencode"

path_line='export PATH="$HOME/.local/bin:$PATH"'
touch "$HOME/.bashrc"
if ! grep -Fqx "$path_line" "$HOME/.bashrc"; then
  printf '%s\n' "$path_line" >> "$HOME/.bashrc"
fi

"$HOME/.local/bin/opencode" --version
printf '%s\n' 'Installed at ~/.local/bin/opencode. Run: export PATH="$HOME/.local/bin:$PATH"'
