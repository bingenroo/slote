#!/usr/bin/env bash
# Installed to ~/.local/lib/ — ~/.local/bin/{draw,emulator,...} are symlinks or stubs here.
set -euo pipefail

TOOL="${SLOTE_DISPATCH_TOOL:-$(basename "$0")}"
SL_RESOLVE="${HOME}/.local/lib/slote-resolve-repo.sh"
if [[ ! -r "${SL_RESOLVE}" ]]; then
  printf '%s\n' "slote: missing ${SL_RESOLVE} (run scripts/install-local-shims.sh from Slote)" >&2
  exit 127
fi
# shellcheck source=/dev/null
. "${SL_RESOLVE}"

_slote_sdk_emulator() {
  local h="${ANDROID_HOME:-}"
  [[ -z "${h}" ]] && h="${ANDROID_SDK_ROOT:-}"
  [[ -z "${h}" ]] && h="${HOME}/Android/Sdk"
  local base="${h}/emulator/emulator"
  local u
  u="$(uname -s 2>/dev/null || printf '')"
  case "${u}" in
    MINGW* | MSYS* | CYGWIN*)
      if [[ -x "${base}.exe" ]]; then
        printf '%s' "${base}.exe"
        return
      fi
      ;;
  esac
  if [[ -x "${base}.exe" ]]; then
    printf '%s' "${base}.exe"
    return
  fi
  printf '%s' "${base}"
}

unset SLOTE_DISPATCH_TOOL 2>/dev/null || true

if root="$(_slote_resolve_repo_root)"; then
  target="${root}/bin/${TOOL}"
  if [[ -e "${target}" ]] && [[ -x "${target}" ]]; then
    exec "${target}" "$@"
  fi
  printf '%s\n' "slote: ${TOOL} not found or not executable in ${root}/bin" >&2
  exit 127
fi

if [[ "${TOOL}" == "emulator" ]]; then
  sdk_bin="$(_slote_sdk_emulator)"
  if [[ ! -x "${sdk_bin}" ]]; then
    printf '%s\n' "slote: repo not found and SDK emulator missing: ${sdk_bin}" >&2
    exit 127
  fi
  if [[ "${1:-}" == "launch" ]]; then
    printf '%s\n' "slote-emulator: Slote not detected — cd into the repo or export SLOTE_ROOT." >&2
  fi
  exec "${sdk_bin}" "$@"
fi

printf '%s\n' "slote: command '${TOOL}' needs the Slote repo — cd into it or export SLOTE_ROOT." >&2
exit 127
