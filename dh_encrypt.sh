#!/bin/bash
# ===========================================
# 🍌 BananaBot9000 DH Key Exchange - Script 2 of 3
# ENCRYPT: Encrypt a secret to send to BananaBot
# ===========================================

set -e

SAVE_DIR="$HOME/.dh_exchange"

if [ ! -f "$SAVE_DIR/aes_key.hex" ]; then
    echo "❌ Error: Run ./dh_keygen.sh first!"
    exit 1
fi

AES_KEY=$(cat "$SAVE_DIR/aes_key.hex")

echo ""
echo "🍌 BananaBot9000 Secret Encryptor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Type or paste your secret below."
echo "(Input is hidden for security)"
echo ""

read -s -p "🔑 Secret: " SECRET
echo ""
echo ""

if [ -z "$SECRET" ]; then
    echo "❌ Error: No secret provided!"
    exit 1
fi

# --- Generate random IV ---
IV=$(openssl rand -hex 16)

# --- Encrypt with AES-256-CBC, output as base64 ---
ENCRYPTED=$(echo -n "$SECRET" | openssl enc -aes-256-cbc -a -A -K "$AES_KEY" -iv "$IV" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Encryption failed!"
    exit 1
fi

# --- Combine IV:base64_ciphertext ---
PAYLOAD="${IV}:${ENCRYPTED}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Encrypted! Paste this in Discord for BananaBot:"
echo ""
echo "    $PAYLOAD"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Only BananaBot can decrypt this"
echo "👀 Anyone else will just see gibberish"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
