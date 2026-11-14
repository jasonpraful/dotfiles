# Mac config

Plain dotfiles + a Brewfile for setting up my Mac. No Nix.

```
Brewfile              # every CLI tool, app and font (Homebrew)
Brewfile.local        # optional, git-ignored: machine-only extras
config/git/           # ~/.config/git/{config,ignore} (symlinked)
assets/ssh/           # ~/.ssh files (git-crypt encrypted, copied with 600 perms)
assets/*.itermexport  # iTerm2 export (encrypted, import manually)
assets/*.rayconfig    # Raycast export (encrypted, import manually)
scripts/bootstrap.sh  # Homebrew + Brewfile + config links + Vite+ Node (+ SSH with --ssh)
scripts/defaults.sh   # macOS preferences (Dock, keyboard, Finder, Touch ID sudo, ...)
scripts/github-keys.sh # this Mac's own GitHub keys in the Secure Enclave (SSH auth + commit signing)
Makefile              # shortcuts: bootstrap, unlock, ssh, github-keys, defaults, update, save-key
```

## New Mac

```bash
# 1. Xcode command line tools (gives git)
xcode-select --install

# 2. Clone
git clone git@github.com:jasonpraful/dotfiles.git ~/.config/dotfiles   # or https:// before SSH is set up
cd ~/.config/dotfiles

# 3. Install everything (installs Homebrew if missing). Preview first with scripts/bootstrap.sh --dry-run
make bootstrap

# 4. Open 1Password, sign in, enable Settings → Developer → "Integrate with 1Password CLI".
#    Then decrypt the repo (key comes from the 1Password document "Nix-Config - Git Crypt" (Private vault)),
#    copy the SSH files into ~/.ssh (existing ones are backed up first), and create this Mac's own
#    GitHub keys (asks for a name, e.g. "Personal Mac Mini", and two quick GitHub approvals)
make ssh

# 5. macOS preferences (asks for sudo)
make defaults
```

Re-running either script is safe. Anything bootstrap would replace is moved aside as `*.backup-<timestamp>`.

## Day to day

```bash
make update                                  # brew update + upgrade + install anything new in the Brewfile
brew bundle --file Brewfile                  # install anything newly added to the Brewfile
brew bundle cleanup --file Brewfile          # list installed things not in the Brewfile (add --force to remove)
brew bundle dump --file - --no-vscode        # see what's installed, to copy lines into the Brewfile
```

Node.js (and npm/pnpm/yarn) is managed by [Vite+](https://viteplus.dev/guide/env): `vp env default lts` for the global default, `vp env pin 24` in a project (writes `.node-version`), `vp env doctor` to check. Python versions by pyenv or uv.

## git-crypt key

`assets/ssh/*`, the iTerm2 export and the Raycast export are encrypted on GitHub. The key is stored in 1Password (Private vault) as the document **Nix-Config - Git Crypt**; `make unlock` fetches it and decrypts the repo. To (re)upload the key from an unlocked checkout: `make save-key`.

## GitHub keys (per Mac)

Each Mac gets its own GitHub keys, created in the Secure Enclave by `make github-keys` (also part of `make ssh`):

- **`<name>`**: SSH authentication for `github.com`. **`<name> Signing`**: signs every commit and tag (shows as Verified).
- The keys can't be exported and need no Touch ID or 1Password, so git works when the Mac is unattended. Revoke one Mac by deleting its keys on GitHub.
- Only `github.com` uses them (`~/.ssh/config.local`); every other host still goes through the 1Password agent.
- `gh` gets key-admin permission only while uploading, then it's removed again.
- Machine-only files (not in this repo): `~/.ssh/config.local`, `~/.config/git/config.local`, `~/.config/git/allowed_signers`.
