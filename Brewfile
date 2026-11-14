# Mac setup: `brew bundle --file ~/.config/dotfiles/Brewfile`
# Machine-only extras go in Brewfile.local (git-ignored); bootstrap.sh picks it up.

# --- Taps ------------------------------------------------------------------
tap "antoniorodr/memo"
tap "hashicorp/tap", trusted: true
tap "moul/moul", trusted: { formulae: ["totp-keychain"] }
tap "openclaw/tap"
tap "oven-sh/bun", trusted: true
tap "steipete/tap"
tap "stripe/stripe-cli", trusted: true
tap "teamookla/speedtest"

# --- Shell & core CLI --------------------------------------------------------
brew "coreutils"          # GNU tools, g-prefixed (gls, gnumfmt, ...)
brew "dockutil"           # used by scripts/defaults.sh for the Dock
brew "jq"
brew "neovim"
brew "ripgrep"
brew "tmux"
brew "tree"
brew "watchman"
brew "wget"
brew "python-yq"         # jq wrapper: yq / xq / tomlq

# --- Git ---------------------------------------------------------------------
brew "gh"
brew "git"
brew "git-crypt"
brew "git-delta"
brew "git-lfs"
brew "gitleaks"

# --- Languages & runtimes ----------------------------------------------------
brew "bash"
brew "bun"
brew "go"
brew "node@24"
brew "pyenv"
brew "python@3.12"
brew "uv"
brew "volta"              # Node toolchains (node/npm/pnpm/yarn shims)
cask "zulu@21"             # Java 21 JDK

# --- Build deps --------------------------------------------------------------
brew "cmake"
brew "openjpeg"
brew "openssl@3"
brew "pixman"
brew "pkgconf"

# --- Cloud, infra & k8s ------------------------------------------------------
brew "awscli"
cask "azure-cli"
brew "cloudflared"
brew "helm"
brew "kind"
brew "kubectx"
brew "kubernetes-cli"
brew "k9s"
brew "minikube"
brew "mongodb-atlas-cli"
brew "hashicorp/tap/terraform"
brew "terraform-ls"
brew "stripe/stripe-cli/stripe"

# --- Data stores -------------------------------------------------------------
brew "mongosh"
brew "postgresql@14"
brew "postgresql@18"
brew "redis"

# --- Mobile ------------------------------------------------------------------
brew "apktool"
brew "cocoapods"
brew "fastlane"
brew "jadx"
brew "swiftformat"
brew "xcodegen"

# --- Media, docs & misc CLI --------------------------------------------------
brew "asciinema"
brew "ffmpeg"
brew "imagemagick"
brew "mas"
brew "mkcert"
brew "mkdocs"
brew "nmap"
brew "openai-whisper"
brew "opencode"
brew "pass"
brew "poppler"
brew "sshpass"
brew "tesseract"
brew "himalaya"
brew "antoniorodr/memo/memo", trusted: true
brew "moul/moul/totp-keychain", trusted: true
brew "openclaw/tap/gogcli", trusted: true
brew "teamookla/speedtest/speedtest", trusted: true

# --- Fonts -------------------------------------------------------------------
cask "font-geist-mono-nerd-font"
cask "font-hack-nerd-font"
cask "font-meslo-for-powerlevel10k"

# --- Apps --------------------------------------------------------------------
cask "1password"
cask "1password-cli"
cask "adapter"
cask "adobe-acrobat-reader"
cask "android-studio"
cask "antigravity"
cask "blender"
cask "claude"
cask "steipete/tap/codexbar", trusted: true
cask "comet"
cask "cursor"
cask "dbeaver-community"
cask "discord"
cask "disk-drill"
cask "docker-desktop"
cask "figma@beta"
cask "ghostty"
cask "google-chrome"
cask "helium-browser"
cask "iterm2"
cask "keycastr"
cask "logi-options+"
cask "macs-fan-control"
cask "menumeters"
cask "microsoft-auto-update"
cask "microsoft-teams"
cask "obsidian"
cask "pgadmin4"
cask "postman"
cask "proxyman"
cask "raycast"
cask "runjs"
cask "rustdesk"
cask "slack@beta"
cask "superhuman"
cask "superwhisper"
cask "tailscale-app"
cask "teamviewer"
cask "visual-studio-code"
cask "whatsapp@beta"
cask "wispr-flow"
