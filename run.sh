#!/usr/bin/env bash
# run.sh — Ensures Ruby 2.6.x is available and launches coupler.rb

set -uo pipefail

REQUIRED_RUBY="2.6.10"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──────────────────────────────────────────
# 헬퍼 함수
# ──────────────────────────────────────────

info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# 현재 활성화된 ruby 가 2.6.x 인지 확인 (true=0, false=1)
ruby_ok() {
  command -v ruby &>/dev/null || return 1
  ruby -e "exit(RUBY_VERSION.start_with?('2.6') ? 0 : 1)" 2>/dev/null
}

# rbenv init 을 현재 셸에 적용
init_rbenv() {
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)" 2>/dev/null || true
}

# ──────────────────────────────────────────
# rbenv 를 통한 Ruby 2.6.10 설치
# ──────────────────────────────────────────

install_via_rbenv() {
  # rbenv 자체가 없으면 설치
  if ! command -v rbenv &>/dev/null; then
    info "rbenv not found. Installing rbenv..."

    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS: Homebrew 필요
      if ! command -v brew &>/dev/null; then
        error "Homebrew is required on macOS but was not found.\nInstall it from https://brew.sh and re-run this script."
      fi
      brew install rbenv ruby-build
    else
      # Linux: git clone
      if ! command -v git &>/dev/null; then
        error "git is required to install rbenv but was not found."
      fi
      git clone https://github.com/rbenv/rbenv.git    "$HOME/.rbenv"
      git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
      # C 확장 빌드 (실패해도 계속)
      (cd "$HOME/.rbenv" && src/configure && make -C src) 2>/dev/null || true
    fi
  fi

  init_rbenv

  # ruby-build 플러그인 확인
  if ! rbenv install --list &>/dev/null; then
    error "ruby-build plugin is not available. Please install it manually."
  fi

  # Ruby 2.6.10 이 아직 설치되지 않은 경우에만 설치
  if ! rbenv versions --bare 2>/dev/null | grep -qx "$REQUIRED_RUBY"; then
    info "Installing Ruby $REQUIRED_RUBY via rbenv (this may take a few minutes)..."
    rbenv install "$REQUIRED_RUBY"
  else
    info "Ruby $REQUIRED_RUBY is already installed in rbenv."
  fi

  # 프로젝트 디렉터리에 .ruby-version 설정
  rbenv local "$REQUIRED_RUBY"
  init_rbenv
}

# ──────────────────────────────────────────
# 메인 흐름
# ──────────────────────────────────────────

cd "$SCRIPT_DIR"

if ruby_ok; then
  info "Ruby $(ruby -e 'print RUBY_VERSION') detected. Skipping installation."
else
  warn "Ruby 2.6.x not found. Starting installation..."
  install_via_rbenv

  # 설치 후 재확인
  if ! ruby_ok; then
    error "Ruby 2.6.x installation failed. Please install Ruby $REQUIRED_RUBY manually."
  fi
  info "Ruby $(ruby -e 'print RUBY_VERSION') is now ready."
fi

info "Launching coupler.rb..."
echo ""
exec ruby "$SCRIPT_DIR/coupler.rb"
