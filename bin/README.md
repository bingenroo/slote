# Slote command shims

Run Slote commands without the `python3 cmd.py` prefix by adding this directory to your PATH. The scripts in `bin/` are Bash; they work in macOS Terminal, Linux, and in Git Bash / WSL on Windows.

**Important:** Slote’s `bin` must come **before** the Android SDK in PATH, otherwise `emulator` runs the SDK’s binary (which has no default AVD) instead of this script. Use `.../Slote/bin:$PATH` (Slote first).

## One-time (current shell only)

```bash
cd /path/to/Slote
export PATH="$PWD/bin:$PATH"
rehash
emulator launch
```

## Permanent (global terminal — all new windows/tabs)

This applies to **every new terminal** you open on that machine. Add the line below to your shell config, using your actual Slote path. Slote’s `bin` must be at the **start** of PATH so it overrides the Android SDK `emulator`.

| Platform | Config file | Add this line |
|----------|-------------|----------------|
| **macOS** (zsh) | `~/.zshrc` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Linux** (bash) | `~/.bashrc` or `~/.profile` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Linux** (zsh) | `~/.zshrc` | `export PATH="/path/to/Slote/bin:$PATH"` |
| **Windows** (Git Bash / WSL) | `~/.bashrc` or `~/.bash_profile` | `export PATH="/c/path/to/Slote/bin:$PATH"` |

Then open a new terminal or run `source ~/.zshrc` (or `source ~/.bashrc`) and `rehash`. Verify with `which emulator` — it should show `.../Slote/bin/emulator`.

**Windows (PowerShell / CMD):** These shims are Bash scripts. Use `python cmd.py ...` from the repo root instead (e.g. `python cmd.py emulator launch`), or use Git Bash / WSL and the table above.

## Without changing PATH

From the Slote repo root you can always run:

```bash
./bin/emulator launch
./bin/bootstrap
./bin/viewport flutter run
./bin/draw flutter pub get
```

See the main [README.md](../README.md) for full setup and troubleshooting (e.g. “No AVD specified”).
