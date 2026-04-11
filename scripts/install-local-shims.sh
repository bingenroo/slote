#!/usr/bin/env bash
# Install ~/.local shims for Slote bin/* (no hardcoded repo path in shell config).
# Re-run after adding a new executable under bin/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${REPO_ROOT}/scripts/local-shims"
LIB="${HOME}/.local/lib"
BIN="${HOME}/.local/bin"
DISPATCH="${LIB}/slote-cli-dispatch.sh"

_slote_windows_like_shell() {
  case "$(uname -s 2>/dev/null || printf '')" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

_write_dispatch_stub() {
  local name="$1"
  local dest="${BIN}/${name}"
  if [[ ! "${name}" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    printf '%s\n' "install-local-shims: skipping unsafe tool name: ${name}" >&2
    return 1
  fi
  # LF-only heredoc (avoid CRLF breaking shebang on Windows editors)
  cat >"${dest}" <<EOF
#!/usr/bin/env bash
export SLOTE_DISPATCH_TOOL=${name}
exec bash '${DISPATCH}' "\$@"
EOF
  chmod +x "${dest}"
}

mkdir -p "${LIB}" "${BIN}"
cp "${SRC}/slote-resolve-repo.sh" "${LIB}/"
cp "${SRC}/slote-cli-dispatch.sh" "${DISPATCH}"
chmod +x "${DISPATCH}"

use_stubs=0
use_symlinks=0
win_like=0
_slote_windows_like_shell && win_like=1

shopt -s nullglob
for path in "${REPO_ROOT}/bin"/*; do
  name="$(basename "${path}")"
  [[ "${name}" == README.md ]] && continue
  [[ -e "${path}" ]] || continue
  if [[ -x "${path}" || -L "${path}" ]]; then
    rm -f "${BIN}/${name}"
    if [[ "${win_like}" -eq 1 ]]; then
      _write_dispatch_stub "${name}"
      use_stubs=1
      printf '  %s (stub -> slote-cli-dispatch.sh)\n' "${name}"
    elif ln -sf "${DISPATCH}" "${BIN}/${name}" 2>/dev/null; then
      use_symlinks=1
      printf '  %s -> slote-cli-dispatch.sh\n' "${name}"
    else
      _write_dispatch_stub "${name}"
      use_stubs=1
      printf '  %s (stub -> slote-cli-dispatch.sh; symlink failed)\n' "${name}"
    fi
  fi
done

printf '\nInstalled resolver + dispatcher to %s\n' "${LIB}"
if [[ "${use_stubs}" -eq 1 && "${use_symlinks}" -eq 1 ]]; then
  printf 'Mixed symlinks and stubs in %s (see bin/README.md).\n' "${BIN}"
elif [[ "${use_stubs}" -eq 1 ]]; then
  printf 'Stub launchers in %s (Windows/Git Bash or symlink creation unavailable — see bin/README.md).\n' "${BIN}"
else
  printf 'Symlinks in %s.\n' "${BIN}"
fi
printf 'Ensure %s is early on PATH — see bin/README.md.\n' "${BIN}"
