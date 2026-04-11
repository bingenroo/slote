# Slote command shims

Run Slote commands without the `python3 cmd.py` prefix by adding this directory to your PATH. The scripts in `bin/` are Bash; they work in macOS Terminal, Linux, and in Git Bash / WSL on Windows.

**Important:** `emulator` must resolve to Slote’s wrapper (default AVD / `emulator launch`), not the Android SDK binary. Prefer the **local shims** below so nothing in your shell config hardcodes a Slote path.

## Recommended: `~/.local` shims (no hardcoded repo path)

From the Slote repo (any clone location):

```bash
./scripts/install-local-shims.sh
```

This installs `~/.local/lib/slote-resolve-repo.sh` and `slote-cli-dispatch.sh`, then adds one entry per executable name under `bin/` into `~/.local/bin/`: **symlinks** on macOS/Linux when `ln` works, or **small stub scripts** on Git Bash/MSYS/Cygwin (and as a fallback if symlink creation fails, e.g. without Windows Developer Mode). Stubs set `SLOTE_DISPATCH_TOOL` and `exec` the shared dispatcher so behavior matches symlinks. At run time the resolver finds your clone via `SLOTE_ROOT`, the current directory (walk upward), or `git rev-parse --show-toplevel`. Re-run the installer after adding a new CLI under `bin/`.

Put **`~/.local/bin` before `$ANDROID_HOME/emulator` on PATH** (Slote’s `bin/README` used to say “Slote `bin` first”; same idea, but `~/.local/bin` is stable across moves). Example for zsh:

```bash
export PATH="$HOME/.local/bin:$ANDROID_HOME/emulator:$PATH"
```

### Windows (Git Bash / MSYS)

Run `./scripts/install-local-shims.sh` from **Git Bash** (not CMD). The installer uses stubs on Windows so you do not need symlink privileges.

Add to `~/.bashrc` or `~/.bash_profile` (same `PATH` rule as zsh; `$HOME` is usually `/c/Users/...` under Git Bash):

```bash
export PATH="$HOME/.local/bin:$ANDROID_HOME/emulator:$PATH"
```

If you set **`SLOTE_ROOT`**, use a Git Bash–style path (e.g. `/c/Users/you/Code/Slote`), not `C:\...`.

**WSL:** Treat as Linux (`uname` is Linux): symlinks are used if `ln` succeeds; the SDK fallback uses `emulator` without `.exe`.

### Check after install (any OS)

1. `source` your shell config or open a new terminal.
2. `which draw` — should be under `~/.local/bin`.
3. From inside the Slote clone: `draw --help` (or `emulator --help`) should show `cmd.py` usage.
4. From outside the clone (optional): `emulator -help` should show the **Android** emulator help if `ANDROID_HOME` is set; `emulator launch` prints a hint if the Slote repo was not resolved.

## One-time (current shell only)

```bash
cd /path/to/Slote
export PATH="$PWD/bin:$PATH"
rehash
emulator launch
```

## Permanent without shims (PATH to this repo’s `bin`)

If you do not use the installer, add **this clone’s** `bin` at the **start** of PATH so it overrides the Android SDK `emulator`.

| Platform | Config file | Add this line |
|----------|-------------|----------------|
| **macOS** (zsh) | `~/.zshrc` | `export PATH="/path/to/this/Slote/clone/bin:$PATH"` |
| **Linux** (bash) | `~/.bashrc` or `~/.profile` | `export PATH="/path/to/this/Slote/clone/bin:$PATH"` |
| **Linux** (zsh) | `~/.zshrc` | `export PATH="/path/to/this/Slote/clone/bin:$PATH"` |
| **Windows** (Git Bash / WSL) | `~/.bashrc` or `~/.bash_profile` | `export PATH="/c/path/to/this/Slote/clone/bin:$PATH"` |

Then open a new terminal or run `source ~/.zshrc` (or `source ~/.bashrc`) and `rehash`. Verify with `which emulator` — it should show either `~/.local/bin/emulator` (shims) or `.../Slote/bin/emulator` (PATH to repo).

**Windows (PowerShell / CMD):** These shims are Bash scripts. Use `python cmd.py ...` from the repo root instead (e.g. `python cmd.py emulator launch`), or use Git Bash / WSL and the table above.

## Without changing PATH

From the Slote repo root you can always run:

```bash
./bin/emulator launch
./bin/bootstrap
./bin/commit
./bin/commit -s
./bin/viewport flutter run
./bin/draw flutter pub get
```

**commit** — Generate a git commit message from the current repo’s `git status` and `git diff`, preview it in the terminal, and copy it to the clipboard. Runs in the **current directory**, so you can use it from any repo (e.g. from another project under Documents). Use **commit -s** for a one-line message. Requires Ollama running locally (or falls back to a heuristic). Optional: `COMMIT_LLM_MODEL` (default `qwen2.5-coder:7b`), and `pip install pyperclip` for clipboard copy.

See the main [README.md](../README.md) for full setup and troubleshooting (e.g. “No AVD specified”).
