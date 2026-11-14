#!/usr/bin/env bash
# Set up this Mac from the repo: Homebrew + Brewfile, config symlinks, SSH files.
# Safe to re-run. Existing files that would be replaced are moved to *.backup-<timestamp>.
#
#   scripts/bootstrap.sh            # do it
#   scripts/bootstrap.sh --dry-run  # show what would happen
#   scripts/bootstrap.sh --ssh      # also copy assets/ssh/* into ~/.ssh (needs git-crypt unlock)
#
# macOS preferences are separate: scripts/defaults.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
WITH_SSH=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --ssh) WITH_SSH=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
run() { if (( DRY_RUN )); then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }

# link <repo-relative source> <target>
link() {
  local src="$REPO/$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "    ok      $dst"; return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "    backup  $dst -> $dst.backup-$STAMP"
    run mv "$dst" "$dst.backup-$STAMP"
  fi
  echo "    link    $dst -> $src"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}

is_git_crypt_locked() { head -c 10 "$1" 2>/dev/null | grep -q 'GITCRYPT'; }

# --- Homebrew -----------------------------------------------------------------
say "Homebrew"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

bundle() {
  say "$(basename "$1")"
  if (( DRY_RUN )); then
    brew bundle check --file "$1" --verbose || true
  else
    # Keep going if a single package fails; brew prints which ones.
    brew bundle install --file "$1" --no-upgrade || echo "    WARNING: some entries in $(basename "$1") failed; see above"
  fi
}
bundle "$REPO/Brewfile"
[[ -f "$REPO/Brewfile.local" ]] && bundle "$REPO/Brewfile.local"

# --- Config files ---------------------------------------------------------------
say "Config files"
link config/git/config "$HOME/.config/git/config"
link config/git/ignore "$HOME/.config/git/ignore"

# --- SSH (git-crypt encrypted in the repo) -------------------------------------
say "SSH"
if (( ! WITH_SSH )); then
  echo "    skip    pass --ssh to copy assets/ssh/* into ~/.ssh"
elif is_git_crypt_locked "$REPO/assets/ssh/config"; then
  echo "    skip    assets are encrypted; run 'git-crypt unlock <key>' in $REPO and re-run with --ssh"
else
  run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"
  for f in "$REPO"/assets/ssh/*; do
    dst="$HOME/.ssh/$(basename "$f")"
    if [[ -f "$dst" ]] && cmp -s "$f" "$dst"; then echo "    ok      $dst"; continue; fi
    [[ -e "$dst" ]] && { echo "    backup  $dst -> $dst.backup-$STAMP"; run cp -p "$dst" "$dst.backup-$STAMP"; }
    echo "    copy    $dst"
    run install -m 600 "$f" "$dst"
  done
fi

# --- Node via Volta -------------------------------------------------------------
say "Volta"
if command -v volta >/dev/null 2>&1; then
  shim="$(brew --prefix)/bin/volta-shim"
  run mkdir -p "$HOME/.volta/bin"
  for tool in node npm npx pnpm yarn yarnpkg; do
    run ln -sfn "$shim" "$HOME/.volta/bin/$tool"
  done
  echo "    shims   ~/.volta/bin -> $shim"
fi

say "Done. Next: scripts/defaults.sh for macOS preferences (asks for sudo)."
