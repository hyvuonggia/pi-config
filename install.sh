#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/hyvuonggia/pi-config/master"
TARGET_DIR="${HOME}/.pi/agent"
TARGET_FILE="${TARGET_DIR}/APPEND_SYSTEM.md"

echo "==> Installing APPEND_SYSTEM.md to ${TARGET_DIR}"

mkdir -p "${TARGET_DIR}"

# Resolve script directory, with fallback when BASH_SOURCE is unset (piped execution)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
LOCAL_FILE="${SCRIPT_DIR}/APPEND_SYSTEM.md"

if [[ -f "${LOCAL_FILE}" ]]; then
    echo "==> Using local APPEND_SYSTEM.md"
    cp "${LOCAL_FILE}" "${TARGET_FILE}"
else
    echo "==> Downloading APPEND_SYSTEM.md from ${REPO_URL}"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${REPO_URL}/APPEND_SYSTEM.md" -o "${TARGET_FILE}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "${REPO_URL}/APPEND_SYSTEM.md" -O "${TARGET_FILE}"
    else
        echo "ERROR: neither curl nor wget found. Please install one." >&2
        exit 1
    fi
fi

echo "==> Done. Installed to: ${TARGET_FILE}"
