#!/bin/bash
# ===========================================
# Diffie-Hellman Key Exchange - Step 2
# Encrypt your secret (GitHub token) to send to Claude
# ===========================================

SAVE_DIR="$HOME/.dh_exchange"

# --- Check keygen has been run ---
if [ ! -f "$SAVE_DIR/aes_key.hex" ]; then
    echo "❌ Error: Run ./dh_keygen.sh first!"
    exit 1
fi

AES_KEY=$(cat "$SAVE_DIR/aes_key.hex")

echo "🔐 Diffie-Hellman Secret Encryptor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Paste or type your secret (e.g. GitHub token):"
echo "(input is hidden for security)"
echo ""

# --- Read secret without echoing ---
read -s -p "🔑 Secret: " SECRET
echo ""
echo ""

if [ -z "$SECRET" ]; then
    echo "❌ Error: No secret provided!"
    exit 1
fi

# --- Generate random IV ---
IV=$(openssl rand -hex 16)

# --- Encrypt with AES-256-CBC ---
ENCRYPTED=$(echo -n "$SECRET" | openssl enc -aes-256-cbc -a -A -K "$AES_KEY" -iv "$IV" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Encryption failed!"
    exit 1
fi

# --- Combine IV + ciphertext ---
PAYLOAD="${IV}:${ENCRYPTED}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Encrypted! Paste this in Discord for Claude:"
echo ""
echo "    $PAYLOAD"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Only Claude can decrypt this with the shared secret"
echo "👀 Anyone watching Discord will just see gibberish"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
