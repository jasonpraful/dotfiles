#!/usr/bin/env bash
# Give this Mac its own GitHub keys, created in the Secure Enclave (non-exportable, no prompt,
# so they keep working when the Mac runs unattended):
#   "<name>"          SSH authentication key for github.com
#   "<name> Signing"  git commit/tag signing key
# Both are registered on GitHub under the title "<name>". gh is given key-admin permission only
# for the duration of the upload, then it is removed again (two quick browser approvals).
#
# Writes machine-local files (never committed):
#   ~/.ssh/config.local            Host github.com -> this Mac's key (Include'd by ~/.ssh/config)
#   ~/.config/git/config.local     SSH commit signing (include'd by config/git/config)
#   ~/.config/git/allowed_signers  lets `git log --show-signature` verify local commits
#
# Safe to re-run: existing keys are reused and keys already on GitHub are skipped.
#   scripts/github-keys.sh                       # name from a previous run, else asks
#   KEY_NAME="Personal Mac Mini" scripts/github-keys.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROVIDER=/usr/lib/ssh-keychain.dylib
SSH_LOCAL="$HOME/.ssh/config.local"
GIT_LOCAL="$HOME/.config/git/config.local"
SIGNERS="$HOME/.config/git/allowed_signers"
WRAPPER="$REPO/scripts/ssh-keygen-secure-enclave"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$PROVIDER" ]] || die "this macOS has no Secure Enclave SSH support ($PROVIDER missing)"
command -v sc_auth >/dev/null || die "sc_auth not found"
command -v gh >/dev/null || die "gh not installed (it's in the Brewfile)"
gh auth status >/dev/null 2>&1 || { say "Log in to GitHub"; gh auth login --hostname github.com --git-protocol ssh --web; }

# --- Key name --------------------------------------------------------------------
name="${KEY_NAME:-}"
if [[ -z "$name" && -f "$SSH_LOCAL" ]]; then
  name="$(sed -n 's/^# github-key-name: //p' "$SSH_LOCAL" | head -1)"
fi
if [[ -z "$name" ]]; then
  default="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
  read -r -p "Name for this Mac's GitHub keys [$default]: " name
  name="${name:-$default}"
fi
slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g')"
[[ -n "$slug" ]] || die "invalid key name: $name"
auth_label="$name";          auth_key="$HOME/.ssh/id_${slug}_sk"
sign_label="$name Signing";  sign_key="$HOME/.ssh/id_${slug}_signing_sk"
say "Keys for \"$name\""

# --- Secure Enclave keys -----------------------------------------------------------
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Export the key handles (pointers to the Secure Enclave, not secrets) for every SE identity.
# SE keys have no PIN; the askpass settings answer ssh-keygen's PIN prompt with an empty one.
export_handles() {
  rm -rf "${tmp:?}"/*
  (cd "$tmp" && SSH_ASKPASS=/usr/bin/true SSH_ASKPASS_REQUIRE=force DISPLAY="${DISPLAY:-:0}" \
     ssh-keygen -w "$PROVIDER" -K -N "" >/dev/null 2>&1) || true
}

ensure_key() {  # <label> <destination handle path>
  local label="$1" dest="$2" src
  src="$tmp/id_ecdsa_sk_rk_$label"
  export_handles
  if [[ ! -f "$src" ]]; then
    echo "    create  Secure Enclave key \"$label\""
    sc_auth create-ctk-identity -l "$label" -k p-256-ne -t none
    export_handles
  else
    echo "    ok      Secure Enclave key \"$label\" exists"
  fi
  [[ -f "$src" ]] || die "could not export the handle for \"$label\""
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  install -m 600 "$src" "$dest"
  awk -v c="$label" '{print $1, $2, c}' "$src.pub" > "$dest.pub"
  chmod 644 "$dest.pub"
}

ensure_key "$auth_label" "$auth_key"
ensure_key "$sign_label" "$sign_key"

# --- Register on GitHub ----------------------------------------------------------------
say "GitHub"
login="$(gh api user -q .login)"
on_github() {  # <users/{login}/... endpoint> <pubkey file>   (public endpoints, no extra scope)
  local want; want="$(cut -d' ' -f1,2 "$2")"
  gh api "users/$login/$1" --paginate -q '.[].key' | awk '{print $1, $2}' | grep -qxF "$want"
}
need_auth=0; need_sign=0
on_github keys "$auth_key.pub"              && echo "    ok      auth key on GitHub"    || need_auth=1
on_github ssh_signing_keys "$sign_key.pub"  && echo "    ok      signing key on GitHub" || need_sign=1

if (( need_auth || need_sign )); then
  scopes=()
  (( need_auth )) && scopes+=(admin:public_key)
  (( need_sign )) && scopes+=(admin:ssh_signing_key)
  echo "    gh needs temporary permission: ${scopes[*]} (approve in the browser)"
  gh auth refresh -h github.com $(printf -- '-s %s ' "${scopes[@]}")
  drop_scopes() {
    echo "    removing temporary gh permission: ${scopes[*]} (approve in the browser)"
    gh auth refresh -h github.com $(printf -- '-r %s ' "${scopes[@]}") || \
      echo "    WARNING: remove it later with: gh auth refresh -h github.com $(printf -- '-r %s ' "${scopes[@]}")"
  }
  trap 'drop_scopes; rm -rf "$tmp"' EXIT
  (( need_auth )) && gh ssh-key add "$auth_key.pub" --title "$name" --type authentication
  (( need_sign )) && gh ssh-key add "$sign_key.pub" --title "$name" --type signing
fi

# --- SSH: github.com uses this Mac's key, no agent ----------------------------------------
say "SSH config"
cat > "$SSH_LOCAL" <<EOF
# github-key-name: $name
# Written by dotfiles/scripts/github-keys.sh for this Mac only. Do not commit.
Host github.com
	User git
	IdentityFile $auth_key
	IdentitiesOnly yes
	IdentityAgent none
	SecurityKeyProvider $PROVIDER
EOF
chmod 600 "$SSH_LOCAL"
touch "$HOME/.ssh/config"
if ! grep -qxF 'Include ~/.ssh/config.local' "$HOME/.ssh/config"; then
  { echo 'Include ~/.ssh/config.local'; echo; cat "$HOME/.ssh/config"; } > "$tmp/ssh_config"
  install -m 600 "$tmp/ssh_config" "$HOME/.ssh/config"
fi
echo "    ok      $SSH_LOCAL (included first by ~/.ssh/config)"

# --- Git: sign commits and tags with this Mac's signing key ------------------------------
say "Git signing"
mkdir -p "$(dirname "$GIT_LOCAL")"
email="$(git config --global user.email 2>/dev/null || true)"
echo "${email:-*} namespaces=\"git\" $(cut -d' ' -f1,2 "$sign_key.pub") $sign_label" > "$SIGNERS"
cat > "$GIT_LOCAL" <<EOF
# Written by dotfiles/scripts/github-keys.sh for this Mac only. Do not commit.
# Signs commits/tags with the Secure Enclave key "$sign_label" (no prompt, works unattended).
[user]
	signingkey = $sign_key
[gpg]
	format = ssh
[gpg "ssh"]
	program = $WRAPPER
	allowedSignersFile = $SIGNERS
[commit]
	gpgsign = true
[tag]
	gpgsign = true
EOF
echo "    ok      $GIT_LOCAL"

# --- Check ------------------------------------------------------------------------------------
say "Check"
# GitHub's greeting exits 1 even on success, so check the text, not the status.
ssh_out="$(SSH_AUTH_SOCK= ssh -o BatchMode=yes -T git@github.com 2>&1 || true)"
if grep -q 'successfully authenticated' <<<"$ssh_out"; then
  echo "    ok      ssh git@github.com authenticates with \"$auth_label\""
else
  echo "    WARNING: ssh to GitHub did not authenticate; run: ssh -vT git@github.com"
fi
echo test > "$tmp/msg"
if "$WRAPPER" -Y sign -n git -f "$sign_key" "$tmp/msg" >/dev/null 2>&1; then
  echo "    ok      commit signing works with \"$sign_label\""
else
  echo "    WARNING: signing failed; try: $WRAPPER -Y sign -n git -f $sign_key <file>"
fi
