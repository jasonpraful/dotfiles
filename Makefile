SHELL := /bin/bash
# 1Password document holding the git-crypt key (override: make unlock OP_ITEM="...")
OP_ITEM ?= Nix-Config - Git Crypt
OP_VAULT ?= Private
KEY_FILE := .git/git-crypt/keys/default

.PHONY: bootstrap ssh defaults update unlock save-key

## Install Homebrew + Brewfile, link configs
bootstrap:
	scripts/bootstrap.sh

## Decrypt the repo, then copy assets/ssh/* into ~/.ssh
ssh: unlock
	scripts/bootstrap.sh --ssh

## Apply macOS preferences (asks for sudo)
defaults:
	scripts/defaults.sh

## Update Homebrew and everything installed, then install anything new in the Brewfile
update:
	brew update && brew upgrade && brew bundle --file Brewfile

## Decrypt git-crypt files using the key stored in 1Password
unlock:
	@if [[ -f "$(KEY_FILE)" ]]; then echo "Already unlocked."; exit 0; fi; \
	key="$$(mktemp)"; trap 'rm -f "$$key"' EXIT; \
	op document get "$(OP_ITEM)" --vault "$(OP_VAULT)" --out-file "$$key" --force >/dev/null && \
	git-crypt unlock "$$key" && echo "Unlocked."

## One-off: upload this repo's git-crypt key to 1Password
save-key:
	@[[ -f "$(KEY_FILE)" ]] || { echo "Repo is not unlocked; nothing to save."; exit 1; }
	op document create "$(KEY_FILE)" --vault "$(OP_VAULT)" --title "$(OP_ITEM)" --file-name git-crypt.key
