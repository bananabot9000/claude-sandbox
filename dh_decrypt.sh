#!/bin/bash
# ===========================================
# 🍌 BananaBot9000 DH Key Exchange - Script 3 of 3
# DECRYPT: Decrypt a message FROM BananaBot
# ===========================================

set -e

SAVE_DIR="$HOME/.dh_exchange"

if [ ! -f "$SAVE_DIR/aes_key.hex" ]; then
    echo "❌ Error: Run ./dh_keygen.sh first!"
    exit 1
fi

AES_KEY=$(cat "$SAVE_DIR/aes_key.hex")

echo ""
echo "🍌 BananaBot9000 Message Decryptor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Paste the encrypted message from BananaBot:"
echo "(format: IV:base64_ciphertext)"
echo ""

read -p "🔐 Encrypted message: " PAYLOAD

if [ -z "$PAYLOAD" ]; then
    echo "❌ Error: No payload provided!"
    exit 1
fi

# --- Split IV and ciphertext ---
IV=$(echo "$PAYLOAD" | cut -d':' -f1)
CIPHERTEXT=$(echo "$PAYLOAD" | cut -d':' -f2-)

if [ -z "$IV" ] || [ -z "$CIPHERTEXT" ]; then
    echo "❌ Error: Invalid payload format. Expected IV:ciphertext"
    exit 1
fi

# --- Validate IV is 32 hex chars ---
if [ ${#IV} -ne 32 ]; then
    echo "❌ Error: Invalid IV length (expected 32 hex chars, got ${#IV})"
    exit 1
fi

# --- Decrypt with AES-256-CBC ---
DECRYPTED=$(echo -n "$CIPHERTEXT" | openssl enc -aes-256-cbc -d -a -A -K "$AES_KEY" -iv "$IV" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Decryption failed! Wrong key or corrupted message."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Decrypted message from BananaBot:"
echo ""
echo "    $DECRYPTED"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
