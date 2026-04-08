#!/usr/bin/env bash
# =============================================================================
# setup-ai-lab-env.sh
# Sets up the Vitest development environment in the AI Lab workspace on Ubuntu.
# Designed to run without root (except for system-level deps if needed).
# Usage:  bash scripts/setup-ai-lab-env.sh
# =============================================================================

set -euo pipefail

WORKSPACE="${WORKSPACE:-$HOME/workspace}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NODE_VERSION="22"   # LTS release within the supported range (^20 || ^22 || >=24)
PNPM_VERSION="10"   # major version; exact version managed by corepack

# ── helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m    $*"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
die()     { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# ── 0. Prerequisites check ───────────────────────────────────────────────────
info "Checking system prerequisites..."

for cmd in curl git bash; do
  command -v "$cmd" &>/dev/null || die "'$cmd' is required but not found. Install it with: sudo apt install $cmd"
done

success "System prerequisites present."

# ── 1. nvm ───────────────────────────────────────────────────────────────────
info "Setting up nvm (Node Version Manager)..."

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  info "nvm not found — installing..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  success "nvm installed."
else
  success "nvm already present at $NVM_DIR."
fi

# Load nvm into current shell
# shellcheck source=/dev/null
export NVM_DIR
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ── 2. Node.js ───────────────────────────────────────────────────────────────
info "Installing Node.js $NODE_VERSION (LTS) via nvm..."
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

NODE_ACTUAL="$(node --version)"
success "Node.js active: $NODE_ACTUAL"

# ── 3. corepack / pnpm ───────────────────────────────────────────────────────
info "Enabling corepack and installing pnpm@$PNPM_VERSION..."
corepack enable
corepack prepare "pnpm@$PNPM_VERSION" --activate 2>/dev/null || true

# Fallback: install pnpm via npm if corepack prepare fails
if ! command -v pnpm &>/dev/null; then
  warn "corepack prepare failed; falling back to: npm install -g pnpm@$PNPM_VERSION"
  npm install -g "pnpm@$PNPM_VERSION"
fi

PNPM_ACTUAL="$(pnpm --version)"
success "pnpm active: v$PNPM_ACTUAL"

# ── 4. Project dependencies ───────────────────────────────────────────────────
info "Installing project dependencies in $REPO_DIR ..."
cd "$REPO_DIR"
pnpm install
success "Dependencies installed."

# ── 5. Build packages ────────────────────────────────────────────────────────
info "Building all packages (pnpm build)..."
pnpm build
success "Build complete."

# ── 6. Workspace symlink (optional convenience) ──────────────────────────────
if [ -d "$WORKSPACE" ]; then
  LINK="$WORKSPACE/vitest"
  if [ ! -e "$LINK" ]; then
    ln -s "$REPO_DIR" "$LINK"
    success "Symlink created: $LINK -> $REPO_DIR"
  else
    info "Symlink/directory already exists at $LINK — skipping."
  fi
else
  warn "Workspace '$WORKSPACE' does not exist — skipping symlink. Set WORKSPACE env var to override."
fi

# ── 7. Shell profile update ───────────────────────────────────────────────────
info "Ensuring nvm is sourced in your shell profile..."

PROFILE_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
NVM_SNIPPET='
# >>> nvm (added by setup-ai-lab-env.sh) >>>
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< nvm <<<'

for profile in "${PROFILE_FILES[@]}"; do
  if [ -f "$profile" ] && ! grep -q 'NVM_DIR' "$profile"; then
    echo "$NVM_SNIPPET" >> "$profile"
    success "Added nvm init to $profile"
  fi
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Vitest AI Lab environment is ready!                     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Node   : $(node --version | tr -d '\n' | awk '{printf "%-52s", $0}')║"
echo "║  pnpm   : v$(pnpm --version | tr -d '\n' | awk '{printf "%-51s", $0}')║"
echo "║  Repo   : $(echo "$REPO_DIR" | awk '{printf "%-52s", $0}')║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Next steps:                                                 ║"
echo "║    pnpm test           → run core tests                      ║"
echo "║    pnpm dev            → watch mode                          ║"
echo "║    pnpm typecheck      → type-check all packages             ║"
echo "║    pnpm lint:fix       → lint & auto-fix                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Open a new terminal (or run 'source ~/.bashrc') for nvm to be available system-wide."
