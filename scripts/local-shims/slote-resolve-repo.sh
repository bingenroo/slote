# Resolve Slote repo root: print absolute path to stdout, or return 1.
# Installed to ~/.local/lib/ by scripts/install-local-shims.sh
# On Windows Git Bash, set SLOTE_ROOT to an MSYS path (e.g. /c/Users/you/Code/Slote), not C:\...
_slote_resolve_repo_root() {
  if [[ -n "${SLOTE_ROOT:-}" && -f "${SLOTE_ROOT}/cmd.py" && -x "${SLOTE_ROOT}/bin/emulator" ]]; then
    printf '%s\n' "${SLOTE_ROOT}"
    return 0
  fi
  local d
  d="$(pwd -P 2>/dev/null || pwd)"
  while [[ "${d}" != "/" ]]; do
    if [[ -f "${d}/cmd.py" && -x "${d}/bin/emulator" ]]; then
      printf '%s\n' "${d}"
      return 0
    fi
    d="$(dirname "${d}")"
  done
  local git_top
  if git_top="$(git -C "$(pwd -P 2>/dev/null || pwd)" rev-parse --show-toplevel 2>/dev/null)"; then
    if [[ -f "${git_top}/cmd.py" && -x "${git_top}/bin/emulator" ]]; then
      printf '%s\n' "${git_top}"
      return 0
    fi
  fi
  return 1
}
