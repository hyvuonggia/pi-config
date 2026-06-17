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

echo "==> Done. Installed APPEND_SYSTEM.md to: ${TARGET_FILE}"

# --- Pi package installs (best-effort) ---
PI_INSTALLED=0
PI_TOTAL=4

if command -v pi >/dev/null 2>&1; then
    set +e

    echo "==> Installing git:github.com/obra/superpowers"
pi install "git:github.com/obra/superpowers"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] git:github.com/obra/superpowers"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] git:github.com/obra/superpowers failed (exit ${rc})"
    fi

    echo "==> Installing npm:context-mode"
pi install "npm:context-mode"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:context-mode"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:context-mode failed (exit ${rc})"
    fi

    echo "==> Installing npm:pi-mcp-adapter"
pi install "npm:pi-mcp-adapter"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:pi-mcp-adapter"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:pi-mcp-adapter failed (exit ${rc})"
    fi

    echo "==> Installing npm:pi-web-access"
pi install "npm:pi-web-access"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:pi-web-access"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:pi-web-access failed (exit ${rc})"
    fi


    set -e
    echo "==> Done. Installed APPEND_SYSTEM.md and ${PI_INSTALLED}/${PI_TOTAL} pi packages."
else
    echo "[WARN] pi CLI not found on PATH — skipping pi package installs"
    echo "==> Done. Installed APPEND_SYSTEM.md. Skipped pi package installs (pi CLI not on PATH)."
fi
