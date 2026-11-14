#!/usr/bin/env bash
# macOS preferences (Dock, keyboard, Finder, Touch ID for sudo, ...).
# Safe to re-run. Some steps need sudo (Touch ID for sudo, guest login, timezone, power).
set -euo pipefail

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

say "Keyboard & input"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3     # full keyboard control

say "Trackpad: tap to click"
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

say "Finder"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

say "Desktop: click wallpaper to show desktop"
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true

say "Dock"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock tilesize -int 40
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock orientation -string bottom
defaults write com.apple.dock mineffect -string genie
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock show-recents -bool true

if command -v dockutil >/dev/null 2>&1; then
  apps=(
    "/System/Applications/Messages.app"
    "/System/Applications/Calendar.app"
    "/System/Applications/FaceTime.app"
    "/System/Applications/App Store.app"
    "/Applications/T3 Code (Nightly).app"
    "/Applications/Google Chrome.app"
    "/Applications/Cursor.app"
    "/System/Applications/System Settings.app"
  )
  dockutil --remove all --no-restart >/dev/null
  for app in "${apps[@]}"; do
    [[ -e "$app" ]] && dockutil --add "$app" --no-restart >/dev/null || echo "    missing $app"
  done
else
  echo "    dockutil not installed; skipping Dock apps (brew install dockutil)"
fi

killall Dock Finder SystemUIServer 2>/dev/null || true

say "System (sudo)"
sudo -v
# Touch ID for sudo, in the file macOS keeps across updates
if ! grep -q pam_tid.so /etc/pam.d/sudo_local 2>/dev/null; then
  echo "auth       sufficient     pam_tid.so" | sudo tee /etc/pam.d/sudo_local >/dev/null
fi
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
sudo systemsetup -settimezone "Europe/London" >/dev/null 2>&1 || true
sudo pmset -a displaysleep 15

say "Done. Some settings need a logout to take effect."
