#!/bin/bash
# ===========================================
# 🍌 BananaBot9000 DH Key Exchange - Script 1 of 3
# KEYGEN: Generate your keypair & compute shared secret
# ===========================================

set -e

# --- Public Parameters (agreed in Discord) ---
P="18446744073709551557"   # 0xFFFFFFFFFFFFFFC5
G="5"

# --- BananaBot's public value (from Discord) ---
BANANA_PUBLIC="13208489604155380137"  # 0xB769D5BE23AAD1A9

SAVE_DIR="$HOME/.dh_exchange"

echo ""
echo "🍌 BananaBot9000 Diffie-Hellman Key Exchange"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Public parameters:"
echo "  Prime (p):              0xFFFFFFFFFFFFFFC5"
echo "  Generator (g):          5"
echo "  BananaBot's public (A): 0xB769D5BE23AAD1A9"
echo ""

# --- Generate your private key (random 8 bytes) ---
echo "🔑 Generating your private key..."
PRIVATE_HEX=$(openssl rand -hex 8)

# --- Compute using node (BigInt support required) ---
RESULT=$(node -e "
function modPow(base, exp, mod) {
  let result = 1n;
  base = base % mod;
  while (exp > 0n) {
    if (exp % 2n === 1n) result = (result * base) % mod;
    exp = exp / 2n;
    base = (base * base) % mod;
  }
  return result;
}

const p = ${P}n;
const g = ${G}n;
const priv = 0x${PRIVATE_HEX}n;
const bananaPub = ${BANANA_PUBLIC}n;

const yourPublic = modPow(g, priv, p);
const sharedSecret = modPow(bananaPub, priv, p);

console.log(yourPublic.toString());
console.log(sharedSecret.toString());
console.log('0x' + yourPublic.toString(16));
console.log('0x' + sharedSecret.toString(16));
")

YOUR_PUBLIC=$(echo "$RESULT" | sed -n '1p')
SHARED_SECRET=$(echo "$RESULT" | sed -n '2p')
YOUR_PUBLIC_HEX=$(echo "$RESULT" | sed -n '3p')
SHARED_SECRET_HEX=$(echo "$RESULT" | sed -n '4p')

# --- Derive AES-256 key from shared secret ---
AES_KEY=$(echo -n "$SHARED_SECRET_HEX" | openssl dgst -sha256 | awk '{print $NF}')

# --- Save everything ---
mkdir -p "$SAVE_DIR"
chmod 700 "$SAVE_DIR"

echo "$PRIVATE_HEX" > "$SAVE_DIR/private_key.hex"
echo "$YOUR_PUBLIC_HEX" > "$SAVE_DIR/public_value.hex"
echo "$SHARED_SECRET_HEX" > "$SAVE_DIR/shared_secret.hex"
echo "$AES_KEY" > "$SAVE_DIR/aes_key.hex"
chmod 600 "$SAVE_DIR"/*

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Keys generated and saved to $SAVE_DIR"
echo ""
echo "📤 YOUR PUBLIC VALUE — paste this in Discord for BananaBot:"
echo ""
echo "    $YOUR_PUBLIC_HEX"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Shared secret computed"
echo "🔑 AES-256 key derived"
echo ""
echo "👉 Next steps:"
echo "   1. Paste the public value above in Discord"
echo "   2. Run ./dh_encrypt.sh to encrypt a message"
echo "   3. Paste the encrypted output in Discord"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
