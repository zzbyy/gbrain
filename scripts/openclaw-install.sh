#!/bin/bash
# openclaw-install.sh — One-click installer for GBrain as OpenClaw plugin with local embeddings
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/zzbyy/gbrain/master/scripts/openclaw-install.sh | bash
#
# What it does:
#   1. Checks prerequisites (bun, jq, ollama)
#   2. Clones to ~/.openclaw/extensions/gbrain
#   3. Installs deps and builds binary
#   4. Pulls local embedding model (nomic-embed-text)
#   5. Registers plugin in openclaw.json
#   6. Initializes GBrain (PGLite local database)
#   7. Prints verification commands

set -e

# ── Ensure interactive stdin (for curl | bash) ──────────────────────────────
if [[ ! -t 0 ]]; then
    [[ -e /dev/tty ]] && exec </dev/tty || { echo "Error: No terminal. Run script directly."; exit 1; }
fi

INSTALL_DIR="$HOME/.openclaw/extensions/gbrain"
OC_CONFIG="$HOME/.openclaw/openclaw.json"
GBRAIN_VERSION="0.9.3"

echo "========================================"
echo "  GBrain — OpenClaw Plugin Installer"
echo "  Local embeddings via Ollama"
echo "========================================"
echo ""

# ── Prerequisites ────────────────────────────────────────────────────────────

echo "Checking prerequisites..."

MISSING=false

if command -v bun &>/dev/null; then
    echo "  [OK] bun $(bun --version)"
else
    echo "  [!!] bun — not found"
    echo "       Install: curl -fsSL https://bun.sh/install | bash"
    MISSING=true
fi

if command -v jq &>/dev/null; then
    echo "  [OK] jq"
else
    echo "  [!!] jq — not found"
    echo "       Install: brew install jq"
    MISSING=true
fi

if command -v ollama &>/dev/null; then
    echo "  [OK] ollama"
else
    echo "  [!!] ollama — not found (needed for local embeddings)"
    echo "       Install the Ollama desktop app or: brew install ollama"
    MISSING=true
fi

if [ "$MISSING" = true ]; then
    echo ""
    echo "Install missing prerequisites first, then re-run."
    exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo ""
    echo "  [!!] Ollama is not running. Start it first:"
    echo "       Open Ollama app, or run: ollama serve &"
    exit 1
fi
echo "  [OK] ollama is running"

echo ""

# ── Pull embedding model ────────────────────────────────────────────────────

echo "Pulling embedding model (nomic-embed-text)..."
if ollama list 2>/dev/null | grep -q 'nomic-embed-text'; then
    echo "  [OK] nomic-embed-text already pulled"
else
    ollama pull nomic-embed-text
    echo "  [OK] nomic-embed-text pulled"
fi

echo ""

# ── Clone and build ──────────────────────────────────────────────────────────

if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull origin master 2>/dev/null || git pull 2>/dev/null
else
    echo "Cloning gbrain to $INSTALL_DIR..."
    git clone https://github.com/zzbyy/gbrain.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo "Installing dependencies..."
bun install --production 2>&1 | tail -3

echo "Building binary..."
bun run build 2>&1 | tail -3
echo "  [OK] bin/gbrain built"

echo ""

# ── Register in openclaw.json ───────────────────────────────────────────────

echo "Registering plugin in openclaw.json..."

if [ ! -f "$OC_CONFIG" ]; then
    echo "  [!!] openclaw.json not found at $OC_CONFIG"
    echo "       Register manually after OpenClaw is configured."
else
    # Backup
    cp "$OC_CONFIG" "${OC_CONFIG}.bak"

    # Add to allow list (idempotent)
    if jq -e '.plugins.allow | index("gbrain")' "$OC_CONFIG" >/dev/null 2>&1; then
        echo "  [--] already in plugins.allow"
    else
        jq '.plugins.allow += ["gbrain"]' "$OC_CONFIG" > "${OC_CONFIG}.tmp" && mv "${OC_CONFIG}.tmp" "$OC_CONFIG"
        echo "  [OK] added to plugins.allow"
    fi

    # Add entry (idempotent)
    if jq -e '.plugins.entries.gbrain' "$OC_CONFIG" >/dev/null 2>&1; then
        echo "  [--] plugins.entries.gbrain already exists"
    else
        jq '.plugins.entries.gbrain = {"enabled": true, "config": {}}' \
            "$OC_CONFIG" > "${OC_CONFIG}.tmp" && mv "${OC_CONFIG}.tmp" "$OC_CONFIG"
        echo "  [OK] added plugins.entries.gbrain"
    fi

    # Add install record (overwrite to update path)
    jq --arg path "$INSTALL_DIR" --arg ver "$GBRAIN_VERSION" \
        '.plugins.installs.gbrain = {
            "source": "git",
            "sourcePath": "github:zzbyy/gbrain",
            "installPath": $path,
            "version": $ver
        }' "$OC_CONFIG" > "${OC_CONFIG}.tmp" && mv "${OC_CONFIG}.tmp" "$OC_CONFIG"
    echo "  [OK] install record updated"
fi

echo ""

# ── Set up env vars ──────────────────────────────────────────────────────────

echo "Setting up environment variables..."

ZSHRC="$HOME/.zshrc"
ENV_BLOCK='# GBrain local embeddings (Ollama)
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=unused
export GBRAIN_EMBED_MODEL=nomic-embed-text
export GBRAIN_EMBED_DIMENSIONS=768'

if grep -q 'GBRAIN_EMBED_MODEL' "$ZSHRC" 2>/dev/null; then
    echo "  [--] env vars already in .zshrc"
else
    echo "" >> "$ZSHRC"
    echo "$ENV_BLOCK" >> "$ZSHRC"
    echo "  [OK] added to ~/.zshrc"
fi

# Export for current session
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=unused
export GBRAIN_EMBED_MODEL=nomic-embed-text
export GBRAIN_EMBED_DIMENSIONS=768

echo ""

# ── Initialize GBrain ────────────────────────────────────────────────────────

echo "Initializing GBrain (PGLite local database)..."

if [ -d "$HOME/.gbrain" ]; then
    echo "  [--] ~/.gbrain already exists, skipping init"
else
    "$INSTALL_DIR/bin/gbrain" init 2>&1 | tail -5
    echo "  [OK] GBrain initialized"
fi

echo ""

# ── Verify ───────────────────────────────────────────────────────────────────

echo "Verifying..."

# Test embedding endpoint
EMBED_TEST=$(curl -s http://localhost:11434/v1/embeddings \
    -d '{"model":"nomic-embed-text","input":"test"}' \
    -H "Content-Type: application/json" 2>/dev/null | jq -r '.data[0].embedding | length' 2>/dev/null || echo "0")

if [ "$EMBED_TEST" -gt 0 ]; then
    echo "  [OK] Ollama embeddings working (${EMBED_TEST} dimensions)"
else
    echo "  [!!] Ollama embedding test failed — check if ollama is running"
fi

# Test gbrain binary
if "$INSTALL_DIR/bin/gbrain" stats >/dev/null 2>&1; then
    echo "  [OK] gbrain binary works"
else
    echo "  [!!] gbrain binary test failed"
fi

echo ""
echo "========================================"
echo "  Installation Complete"
echo "========================================"
echo ""
echo "Plugin:     $INSTALL_DIR"
echo "Database:   ~/.gbrain/ (PGLite)"
echo "Embeddings: Ollama nomic-embed-text (local, free)"
echo ""
echo "Next steps:"
echo "  1. Restart OpenClaw:  openclaw gateway restart"
echo "  2. Import wiki pages: gbrain import ~/byy/wiki/wiki/pages/"
echo "  3. Embed all pages:   gbrain embed --all"
echo "  4. Test search:       gbrain query \"your question here\""
echo ""
echo "From Feishu, the research agent can now use gbrain tools."
