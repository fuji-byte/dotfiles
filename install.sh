#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

log() {
  printf "\033[1;32m[INFO]\033[0m %s\n" "$*"
}

warn() {
  printf "\033[1;33m[WARN]\033[0m %s\n" "$*"
}

err() {
  printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_sudo() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if have_cmd sudo; then
      SUDO="sudo"
    else
      err "sudo が見つかりません。root で実行するか sudo を入れてください。"
      exit 1
    fi
  else
    SUDO=""
  fi
}

detect_pkg_manager() {
  if have_cmd apt-get; then
    PKG_MANAGER="apt"
  elif have_cmd dnf; then
    PKG_MANAGER="dnf"
  elif have_cmd yum; then
    PKG_MANAGER="yum"
  elif have_cmd pacman; then
    PKG_MANAGER="pacman"
  elif have_cmd brew; then
    PKG_MANAGER="brew"
  elif have_cmd zypper; then
    PKG_MANAGER="zypper"
  else
    PKG_MANAGER=""
  fi
}

pkg_update_once() {
  case "$PKG_MANAGER" in
    apt)
      $SUDO apt-get update
      ;;
    dnf)
      $SUDO dnf makecache
      ;;
    yum)
      $SUDO yum makecache
      ;;
    pacman)
      $SUDO pacman -Sy
      ;;
    zypper)
      $SUDO zypper refresh
      ;;
    brew)
      brew update
      ;;
    *)
      ;;
  esac
}

install_pkg() {
  local pkg="$1"

  case "$PKG_MANAGER" in
    apt)
      $SUDO apt-get install -y "$pkg"
      ;;
    dnf)
      $SUDO dnf install -y "$pkg"
      ;;
    yum)
      $SUDO yum install -y "$pkg"
      ;;
    pacman)
      $SUDO pacman -S --noconfirm "$pkg"
      ;;
    zypper)
      $SUDO zypper install -y "$pkg"
      ;;
    brew)
      brew install "$pkg"
      ;;
    *)
      err "対応しているパッケージマネージャが見つかりません。"
      exit 1
      ;;
  esac
}

ensure_git() {
  if have_cmd git; then
    return
  fi

  log "git がないためインストールします..."
  pkg_update_once

  case "$PKG_MANAGER" in
    apt|dnf|yum|pacman|zypper|brew)
      install_pkg git
      ;;
    *)
      err "git を自動インストールできません。"
      exit 1
      ;;
  esac
}

install_powerlevel10k() {
  if [[ -d "$HOME/powerlevel10k/.git" ]] || [[ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    log "powerlevel10k は既に存在します。"
    return
  fi

  log "powerlevel10k をインストールします..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
}

install_zsh_plugin() {
  local repo="$1"
  local dest="$2"
  local name="$3"

  if [[ -d "$dest/.git" ]] || [[ -e "$dest" ]]; then
    log "$name は既に存在します。"
    return
  fi

  log "$name をインストールします..."
  git clone --depth=1 "$repo" "$dest"
}

ensure_zoxide() {
  if have_cmd zoxide; then
    log "zoxide は既にインストール済みです。"
    return
  fi

  log "zoxide をインストールします..."
  pkg_update_once

  case "$PKG_MANAGER" in
    apt)
      install_pkg zoxide
      ;;
    dnf|yum|pacman|zypper|brew)
      install_pkg zoxide
      ;;
    *)
      warn "zoxide を自動インストールできませんでした。手動で導入してください。"
      ;;
  esac
}

ensure_fzf() {
  if have_cmd fzf; then
    log "fzf は既にインストール済みです。"
    return
  fi

  log "fzf をインストールします..."
  pkg_update_once

  case "$PKG_MANAGER" in
    apt|dnf|yum|pacman|zypper|brew)
      install_pkg fzf
      ;;
    *)
      warn "fzf を自動インストールできませんでした。手動で導入してください。"
      return
      ;;
  esac

  if [[ -d "$HOME/.fzf" && -x "$HOME/.fzf/install" ]]; then
    log "~/.fzf/install を実行します..."
    yes | "$HOME/.fzf/install" --key-bindings --completion --no-update-rc || true
  fi
}

ensure_zsh() {
  if have_cmd zsh; then
    log "zsh は既にインストール済みです。"
    return
  fi

  log "zsh をインストールします..."
  pkg_update_once

  case "$PKG_MANAGER" in
    apt|dnf|yum|pacman|zypper|brew)
      install_pkg zsh
      ;;
    *)
      err "zsh を自動インストールできません。"
      exit 1
      ;;
  esac
}

link_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  ln -snf "$src" "$dst"
  log "リンク作成: $dst -> $src"
}

main() {
  need_sudo
  detect_pkg_manager

  if [[ -z "$PKG_MANAGER" ]]; then
    err "対応しているパッケージマネージャが見つかりません。"
    exit 1
  fi

  log "使用パッケージマネージャ: $PKG_MANAGER"

  ensure_git
  ensure_zsh

  mkdir -p "$HOME/.zsh"

  install_powerlevel10k
  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$HOME/.zsh/zsh-autosuggestions" \
    "zsh-autosuggestions"

  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$HOME/.zsh/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting"

  ensure_zoxide
  ensure_fzf

  if [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
    link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  else
    warn "$DOTFILES_DIR/zsh/.zshrc が見つかりません。"
  fi

  if [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]]; then
    link_file "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  else
    warn ".p10k.zsh はリポジトリにありません。必要なら追加してください。"
  fi

  if [[ -n "${SHELL:-}" ]] && [[ "$SHELL" != "$(command -v zsh)" ]]; then
    warn "ログインシェルが zsh ではありません。必要なら次を実行してください:"
    warn "chsh -s $(command -v zsh)"
  fi

  log "セットアップ完了"
}
main "$@"
