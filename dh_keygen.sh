#!/bin/bash
# ===========================================
# 🍌 BananaBot9000 DH Key Exchange - Script 1 of 3
# KEYGEN: Generate your keypair & compute shared secret
# ===========================================

set -e

# --- Public Parameters (agreed in Discord) ---
# 512-bit prime and generator
P="0xE60B74DB9604C6ACADC01A8D2C3E1D7DEB85632CB2D74C06AD4BF44B520067CF70C5A2621E855ACE6899651A9D40683364F4AAE44B707C29930B2B5AF5EDE811"
G="0xCF4B7E301849415DBC7248CC3F29C46FCF5F88952B82748534F700C32783122615F6EE5ECE1BA4E496016B70F68EECB07D03C07992249096756DEB6D80C2C5FF"

# --- BananaBot's public value (from Discord) ---
BANANA_PUBLIC="0x7568794dcb5d777d367f51dfb9795a1ccf062cc6a5e37ea07be1d94a0a3081336125170b8e44cedc29c481a9186018f56193115987ff86207a4cb092db3c72f5"

SAVE_DIR="$HOME/.dh_exchange"

echo ""
echo "🍌 BananaBot9000 Diffie-Hellman Key Exchange (512-bit)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Public parameters:"
echo "  Prime (p): ${P}"
echo "  Generator: ${G}"
echo "  BananaBot: ${BANANA_PUBLIC}"
echo ""

# --- Generate your private key (256-bit / 32 bytes) ---
echo "🔑 Generating your private key (256-bit)..."
PRIVATE_HEX=$(openssl rand -hex 32)

# --- Compute using node (BigInt) ---
RESULT=$(node -e "
function modPow(base, exp, mod) {
  let result = 1n; base = base % mod;
  while (exp > 0n) {
    if (exp % 2n === 1n) result = (result * base) % mod;
    exp = exp / 2n; base = (base * base) % mod;
  }
  return result;
}

const p = ${P}n;
const g = ${G}n;
const priv = 0x${PRIVATE_HEX}n;
const bananaPub = ${BANANA_PUBLIC}n;

const yourPublic = modPow(g, priv, p);
const sharedSecret = modPow(bananaPub, priv, p);

console.log('0x' + yourPublic.toString(16));
console.log('0x' + sharedSecret.toString(16));
")

YOUR_PUBLIC_HEX=$(echo "$RESULT" | sed -n '1p')
SHARED_SECRET_HEX=$(echo "$RESULT" | sed -n '2p')

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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Keys generated and saved to $SAVE_DIR"
echo ""
echo "📤 YOUR PUBLIC VALUE — paste this in Discord for BananaBot:"
echo ""
echo "    $YOUR_PUBLIC_HEX"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Shared secret computed"
echo "🔑 AES-256 key derived"
echo ""
echo "👉 Next steps:"
echo "   1. Paste the public value above in Discord"
echo "   2. Run ./dh_encrypt.sh to encrypt a message"
echo "   3. Paste the encrypted output in Discord"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
