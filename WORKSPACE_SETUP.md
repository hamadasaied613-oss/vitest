# Vitest – Workspace Setup Guide

> Tailored for **Ubuntu 24.04 (Noble)** + **Cursor AI**.  
> Adjust `<YOUR_WORKSPACE>` to your actual workspace path (e.g. `<YOUR_WORKSPACE>`).

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Automated Setup (recommended)](#2-automated-setup-recommended)
3. [Manual Step-by-Step Setup](#3-manual-step-by-step-setup)
4. [Opening the Project in Cursor AI](#4-opening-the-project-in-cursor-ai)
5. [Running Tests with Vitest](#5-running-tests-with-vitest)
6. [Environment Variables](#6-environment-variables)
7. [Recommended Cursor / VS Code Extensions](#7-recommended-cursor--vs-code-extensions)
8. [Troubleshooting Common Ubuntu Issues](#8-troubleshooting-common-ubuntu-issues)

---

## 1. Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Ubuntu | 24.04 (Noble) | Other recent LTS versions also work |
| Node.js | `^20`, `^22`, or `>=24` | Installed via nvm (no root needed) |
| pnpm | `10.x` | Managed via corepack |
| Git | any recent | `sudo apt install git` |
| curl | any recent | `sudo apt install curl` |
| libfuse2t64 | system | Needed to run Cursor AppImage (`sudo apt install libfuse2t64`) |

---

## 2. Automated Setup (recommended)

Clone (or `cd` into) the repository, then run the setup script once:

```bash
# Clone into your workspace (replace <YOUR_WORKSPACE> with the actual path)
cd <YOUR_WORKSPACE>
git clone https://github.com/vitest-dev/vitest.git
cd vitest

# Run the setup script (no root required for Node/pnpm)
bash scripts/setup-ai-lab-env.sh
```

The script will:

- Install **nvm** (if absent) and Node.js 22 LTS
- Enable **corepack** and activate pnpm
- Run `pnpm install` to install all project dependencies
- Run `pnpm build` to build all packages
- Create a convenience symlink at `<YOUR_WORKSPACE>/vitest`
- Append nvm initialisation to your `~/.bashrc` / `~/.zshrc`

After the script finishes, open a new terminal or run:

```bash
source ~/.bashrc
```

---

## 3. Manual Step-by-Step Setup

### 3.1 Install nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
```

### 3.2 Install Node.js 22 (LTS)

```bash
nvm install 22
nvm use 22
nvm alias default 22
node --version   # should print v22.x.x
```

### 3.3 Enable pnpm via corepack

```bash
corepack enable
corepack prepare pnpm@10 --activate
pnpm --version   # should print 10.x.x
```

### 3.4 Install project dependencies

```bash
cd <YOUR_WORKSPACE>/vitest   # or wherever you cloned it
pnpm install
```

### 3.5 Build all packages

```bash
pnpm build
```

---

## 4. Opening the Project in Cursor AI

Cursor AI is installed at:

```
<YOUR_WORKSPACE>/apps/cursor/cursor.AppImage
```

### Launch Cursor and open the project

```bash
<YOUR_WORKSPACE>/apps/cursor/cursor.AppImage --no-sandbox \
  <YOUR_WORKSPACE>/vitest
```

> **`--no-sandbox` is required** on Ubuntu 24.04 without extra kernel capabilities.

### Create a launch alias (add to `~/.bashrc`)

```bash
alias cursor='<YOUR_WORKSPACE>/apps/cursor/cursor.AppImage --no-sandbox'
```

Reload the shell, then open any folder with:

```bash
cursor <YOUR_WORKSPACE>/vitest
```

### Recommended Cursor settings

Open **Settings → JSON** (`Ctrl+,` → top-right icon) and add:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "eslint.enable": true,
  "eslint.workingDirectories": [{ "mode": "auto" }],
  "typescript.tsdk": "node_modules/typescript/lib",
  "vitest.enable": true
}
```

---

## 5. Running Tests with Vitest

All commands should be run from the repository root.

| Goal | Command |
|---|---|
| Run core tests | `pnpm test` |
| Run all CI tests | `CI=true pnpm test:ci` |
| Run a single test file | `CI=true pnpm test <filename>` |
| Watch mode | `pnpm dev` |
| Browser tests (Playwright) | `CI=true pnpm test:browser:playwright` |
| Browser tests (WebdriverIO) | `CI=true pnpm test:browser:webdriverio` |
| Type-check | `pnpm typecheck` |
| Lint | `pnpm lint` |
| Lint + auto-fix | `pnpm lint:fix` |

### Example: run a specific test suite

```bash
cd test/core
CI=true pnpm test basic.test.ts
```

---

## 6. Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CI` | _(unset)_ | Set to `true` to enable CI mode (disables watch, enables bail) |
| `WORKSPACE` | `<YOUR_WORKSPACE>` | Used by the setup script for the symlink |
| `NVM_DIR` | `~/.nvm` | nvm installation directory |
| `NODE_OPTIONS` | _(unset)_ | Set to `--max-old-space-size=8192` for heavy builds (see `pnpm dev`) |

---

## 7. Recommended Cursor / VS Code Extensions

These are already listed in `.vscode/extensions.json` and Cursor will prompt you to install them automatically.

| Extension ID | Purpose |
|---|---|
| `vitest.explorer` | Vitest test explorer sidebar |
| `dbaeumer.vscode-eslint` | ESLint integration |
| `esbenp.prettier-vscode` | Prettier formatter |
| `vue.volar` | Vue 3 language support (used in packages/ui) |
| `antfu.unocss` | UnoCSS intellisense (used in packages/ui) |
| `EditorConfig.EditorConfig` | Honour `.editorconfig` settings |
| `streetsidesoftware.code-spell-checker` | Spell checking |

Install all at once from the Cursor command palette:

```
Extensions: Show Recommended Extensions
```

---

## 8. Troubleshooting Common Ubuntu Issues

### `--no-sandbox` crash on startup

**Symptom**: `Failed to move to new namespace … errno = Operation not permitted`

**Fix**: Always launch Cursor with the `--no-sandbox` flag:

```bash
<YOUR_WORKSPACE>/apps/cursor/cursor.AppImage --no-sandbox
```

---

### `pnpm: command not found` after setup

**Cause**: nvm was added to `~/.bashrc` but the current shell hasn't reloaded it.

**Fix**:

```bash
source ~/.bashrc
# then verify:
pnpm --version
```

---

### `node: command not found`

**Fix**: Load nvm and use the installed Node version:

```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 22
```

---

### `EACCES` permission errors with pnpm

**Cause**: pnpm store or cache is on a different filesystem.

**Fix**: Set the pnpm store inside your workspace:

```bash
pnpm config set store-dir <YOUR_WORKSPACE>/.pnpm-store
```

---

### Playwright browsers not found (browser tests only)

```bash
npx playwright install --with-deps
```

---

### `libfuse2t64` not installed

**Symptom**: `fuse: failed to open /dev/fuse: Permission denied` or AppImage fails to extract.

**Fix** (one-time, needs sudo):

```bash
sudo apt install libfuse2t64
```

---

### Out-of-memory during `pnpm build`

```bash
NODE_OPTIONS="--max-old-space-size=8192" pnpm build
```

---

*Happy testing! 🚀*
