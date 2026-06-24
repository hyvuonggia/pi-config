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

# --- Subagent definitions ---
AGENTS_SRC_DIR="${SCRIPT_DIR}/agents"
AGENTS_TARGET_DIR="${TARGET_DIR}/agents"

merge_subagents_settings() {
    local fragment_file="$1"
    local target_file="${TARGET_DIR}/settings.json"

    if [[ ! -f "${target_file}" ]]; then
        echo "==> Creating ${target_file} from repo settings.json"
        cp "${fragment_file}" "${target_file}"
        return 0
    fi

    echo "==> Merging subagents config into ${target_file}"
    set +e
    if command -v jq >/dev/null 2>&1; then
        local tmp
        tmp="$(mktemp)"
        jq -s '.[0] as $user | .[1] as $frag | $user * { subagents: ($user.subagents // {}) * ($frag.subagents // {}) }' "${target_file}" "${fragment_file}" > "${tmp}"
        local jq_rc=$?
        if [[ ${jq_rc} -eq 0 ]] && [[ -s "${tmp}" ]]; then
            mv "${tmp}" "${target_file}"
            echo "    Merged via jq."
            set -e
            return 0
        fi
        rm -f "${tmp}"
        echo "    [WARN] jq merge failed (exit ${jq_rc}) — falling back."
    fi

    if command -v node >/dev/null 2>&1; then
        node -e "
            const fs = require('fs');
            const user = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
            const frag = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
            const fragSub = frag.subagents || {};
            user.subagents = user.subagents || {};
            user.subagents.agentOverrides = Object.assign({}, user.subagents.agentOverrides || {}, fragSub.agentOverrides || {});
            fs.writeFileSync(process.argv[1], JSON.stringify(user, null, 2));
        " "${target_file}" "${fragment_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "    Merged via node."
            set -e
            return 0
        fi
        echo "    [WARN] node merge failed — falling back."
    fi

    echo "[WARN] Neither jq nor node could merge settings.json. Install jq (https://stedolan.github.io/jq/) and re-run install.sh, or merge manually."
    set -e
    return 1
}

# --- MCP Server config ---
merge_mcp_config() {
    local target_file="$1"
    local server_name="context-mode"
    local server_command="context-mode"

    if [[ ! -f "${target_file}" ]]; then
        echo "==> Creating ${target_file} with ${server_name} MCP server"
        mkdir -p "$(dirname "${target_file}")"
        cat > "${target_file}" <<'EOF'
{
  "mcpServers": {
    "context-mode": {
      "command": "context-mode"
    }
  }
}
EOF
        return 0
    fi

    echo "==> Merging ${server_name} MCP server into ${target_file}"
    set +e
    if command -v jq >/dev/null 2>&1; then
        local tmp
        tmp="$(mktemp)"
        jq --arg name "${server_name}" --arg cmd "${server_command}" \
            '.mcpServers = (.mcpServers // {}) | .mcpServers[$name] = {command: $cmd}' \
            "${target_file}" > "${tmp}"
        local jq_rc=$?
        if [[ ${jq_rc} -eq 0 ]] && [[ -s "${tmp}" ]]; then
            mv "${tmp}" "${target_file}"
            echo "    Merged via jq."
            set -e
            return 0
        fi
        rm -f "${tmp}"
        echo "    [WARN] jq merge failed (exit ${jq_rc}) — falling back."
    fi

    if command -v node >/dev/null 2>&1; then
        node -e "
            const fs = require('fs');
            const target = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
            target.mcpServers = target.mcpServers || {};
            target.mcpServers[process.argv[2]] = { command: process.argv[3] };
            fs.writeFileSync(process.argv[1], JSON.stringify(target, null, 2));
        " "${target_file}" "${server_name}" "${server_command}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "    Merged via node."
            set -e
            return 0
        fi
        echo "    [WARN] node merge failed — falling back."
    fi

    echo "[WARN] Neither jq nor node available — cannot merge MCP config into ${target_file}. Install jq (https://stedolan.github.io/jq/) and re-run, or add manually:"
    echo "       { \"mcpServers\": { \"${server_name}\": { \"command\": \"${server_command}\" } } }"
    set -e
    return 1
}

echo "==> Installing subagent definitions to ${AGENTS_TARGET_DIR}"
mkdir -p "${AGENTS_TARGET_DIR}"

SUBFETCHED=0
SUBEXPECTED=7

if [[ -d "${AGENTS_SRC_DIR}" ]]; then
    set +e
    cp -f "${AGENTS_SRC_DIR}"/*.md "${AGENTS_TARGET_DIR}/" 2>/dev/null
    cp_rc=$?
    set -e
    if [[ ${cp_rc} -eq 0 ]]; then
        SUBFETCHED=$(ls -1 "${AGENTS_TARGET_DIR}"/*.md 2>/dev/null | wc -l)
        echo "    Copied ${SUBFETCHED} subagent file(s) from local source."
    fi
else
    SUFFIXES=("council" "designer" "explorer" "fixer" "librarian" "observer" "oracle")
    set +e
    for name in "${SUFFIXES[@]}"; do
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "${REPO_URL}/agents/${name}.md" -o "${AGENTS_TARGET_DIR}/${name}.md" 2>/dev/null && SUBFETCHED=$((SUBFETCHED + 1))
        elif command -v wget >/dev/null 2>&1; then
            wget -q "${REPO_URL}/agents/${name}.md" -O "${AGENTS_TARGET_DIR}/${name}.md" 2>/dev/null && SUBFETCHED=$((SUBFETCHED + 1))
        fi
    done
    set -e
    echo "    Downloaded ${SUBFETCHED}/${#SUFFIXES[@]} subagent file(s) from ${REPO_URL}."
fi

# --- Settings.json merge (subagents config only) ---
SETTINGS_FRAGMENT="${SCRIPT_DIR}/settings.json"
if [[ -f "${SETTINGS_FRAGMENT}" ]]; then
    merge_subagents_settings "${SETTINGS_FRAGMENT}"
else
    set +e
    TMP_SETTINGS="$(mktemp)"
    fetch_rc=1
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${REPO_URL}/settings.json" -o "${TMP_SETTINGS}" 2>/dev/null && fetch_rc=0
    elif command -v wget >/dev/null 2>&1; then
        wget -q "${REPO_URL}/settings.json" -O "${TMP_SETTINGS}" 2>/dev/null && fetch_rc=0
    fi
    if [[ ${fetch_rc} -eq 0 ]] && [[ -f "${TMP_SETTINGS}" ]]; then
        merge_subagents_settings "${TMP_SETTINGS}"
    fi
    rm -f "${TMP_SETTINGS}"
    set -e
fi

# --- Pi package installs (best-effort) ---
PI_INSTALLED=0
PI_TOTAL=9

if [[ "${PI_NO_INSTALL:-0}" == "1" ]]; then
    echo "[SKIP] PI_NO_INSTALL=1 — skipping pi package installs"
elif command -v pi >/dev/null 2>&1; then
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

    echo "==> Installing npm:pi-caveman"
pi install "npm:pi-caveman"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:pi-caveman"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:pi-caveman failed (exit ${rc})"
    fi

    echo "==> Installing npm:@juicesharp/rpiv-todo"
pi install "npm:@juicesharp/rpiv-todo"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:@juicesharp/rpiv-todo"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:@juicesharp/rpiv-todo failed (exit ${rc})"
    fi

    echo "==> Installing npm:pi-powerline-footer"
pi install "npm:pi-powerline-footer"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:pi-powerline-footer"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:pi-powerline-footer failed (exit ${rc})"
    fi

    echo "==> Installing npm:@vndv/pi-codegraph"
pi install "npm:@vndv/pi-codegraph"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:@vndv/pi-codegraph"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:@vndv/pi-codegraph failed (exit ${rc})"
    fi

    echo "==> Installing npm:pi-subagents"
pi install "npm:pi-subagents"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        echo "[OK] npm:pi-subagents"
        PI_INSTALLED=$((PI_INSTALLED + 1))
    else
        echo "[WARN] npm:pi-subagents failed (exit ${rc})"
    fi

    set -e
    echo "==> Done. Installed APPEND_SYSTEM.md, ${SUBFETCHED}/${SUBEXPECTED} subagents, and ${PI_INSTALLED}/${PI_TOTAL} pi packages."
else
    echo "[WARN] pi CLI not found on PATH — skipping pi package installs"
    echo "==> Done. Installed APPEND_SYSTEM.md and ${SUBFETCHED}/${SUBEXPECTED} subagents. Skipped pi package installs (pi CLI not on PATH)."
fi

# --- MCP Server config (system-level) ---
MCP_TARGET="${HOME}/.pi/agent/mcp.json"
echo "==> Configuring context-mode MCP server at ${MCP_TARGET}"
merge_mcp_config "${MCP_TARGET}"
