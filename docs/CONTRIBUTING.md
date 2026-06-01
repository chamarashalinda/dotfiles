# Contributing

---

## Module Interface Contract

Every `modules/*/install.sh` must follow this contract:

1. **Source detect.sh first**
   ```bash
   source "$REPO_ROOT/bootstrap/detect.sh"
   ```

2. **Be idempotent** — every install action is guarded by a check
   ```bash
   if ! command -v mytool &>/dev/null; then
     # install
   else
     done_ "mytool already installed"
   fi
   ```

3. **Consistent output helpers**
   ```bash
   log()   { echo -e "${CYAN}→${RESET} $*"; }   # action in progress
   done_() { echo -e "${GREEN}✔${RESET} $*"; }  # step completed
   skip()  { echo -e "${YELLOW}–${RESET} Skipping $*"; }  # intentionally skipped
   ```

4. **Accept env-var overrides** — document them in the file header comment

5. **bash 3.2 compatible** — no `declare -A`, no `mapfile`. macOS ships with bash 3.2.

6. **`set -euo pipefail` at the top** — fail fast on errors

---

## Adding a Module

### 1. Create the script

```bash
mkdir -p modules/mymodule
```

```bash
#!/usr/bin/env bash
# modules/mymodule/install.sh — What this module does
#
# Env vars:
#   SKIP_MYTOOL   set to 1 to skip installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
skip()  { echo -e "${YELLOW}–${RESET} Skipping $*"; }

echo -e "\n${BOLD}[mymodule] Installing...${RESET}\n"

if [[ "${SKIP_MYTOOL:-0}" == "1" ]]; then
  skip "mytool"
else
  if ! command -v mytool &>/dev/null; then
    log "Installing mytool..."
    if is_mac; then
      brew install mytool
    else
      sudo apt-get install -y mytool
    fi
    done_ "mytool installed"
  else
    done_ "mytool already installed"
  fi
fi

echo -e "\n${GREEN}${BOLD}[mymodule] Done.${RESET}\n"
```

### 2. Add a Makefile target

```makefile
## mymodule: Short description of what it installs
mymodule:
	@bash modules/mymodule/install.sh
```

### 3. Add to relevant profiles

Edit `profiles/sre-platform.sh` (or whichever profiles need it) and add the module in the correct install order.

### 4. Add to verify.sh (optional)

If the module installs a binary that should be verified:

```bash
_check_cmd "mytool" mytool "--version"
```

---

## Adding a Profile

```bash
cp profiles/minimal.sh profiles/myprofile.sh
```

Edit the new file — source the modules you need in install order, with appropriate env-var overrides:

```bash
bash "$REPO_ROOT/modules/shell/install.sh"
bash "$REPO_ROOT/modules/packages/install.sh"
SKIP_RUST=1 bash "$REPO_ROOT/modules/languages/install.sh"
bash "$REPO_ROOT/modules/dotfiles/install.sh"
```

Test it:

```bash
make bootstrap PROFILE=myprofile
# or
bash install.sh --profile myprofile --dry-run
bash install.sh --profile myprofile
```

---

## Adding a Dotfile

Add the file to `dotfiles/` using chezmoi naming conventions:

| Source name | Deployed to | Use when |
|---|---|---|
| `dot_filename` | `~/.filename` | Plain file, no templating needed |
| `dot_filename.tmpl` | `~/.filename` | Needs OS/machine-specific content |
| `private_dot_filename` | `~/.filename` (mode 600) | Sensitive file |
| `private_dot_filename.tmpl` | `~/.filename` (mode 600) | Sensitive + templated |

Test the template renders correctly before committing:

```bash
chezmoi apply --source="$(pwd)/dotfiles" --dry-run --verbose
```

---

## Testing

### Before opening a PR

- [ ] Run the module standalone: `make <module>`
- [ ] Run `make verify` and confirm 0 failures for the tools your module adds
- [ ] Re-run the module a second time and confirm it skips cleanly (idempotency check)
- [ ] Test on a clean environment if possible:
  - **macOS**: fresh user account or a VM
  - **Linux**: `docker run -it ubuntu:22.04 bash` then run install

### Quick local test

```bash
bash install.sh --profile minimal --dry-run   # sanity check
make verify                                    # check current state
```

---

## Commit style

```
<type>: <short description>

Types: feat, fix, docs, refactor, chore
```

Examples:
```
feat: add neovim module
fix: use binary install for tflint instead of tap
docs: update INSTALL.md for local-only workflow
chore: remove vault from security module
```
