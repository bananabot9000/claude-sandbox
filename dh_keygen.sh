#!/bin/bash
# ===========================================
# Diffie-Hellman Key Exchange - Step 1
# Generate your keypair & compute shared secret
# ===========================================

# --- Public Parameters ---
# (Agreed upon publicly in Discord)
P="0xFFFFFFFFFFFFFFC5"
G="0x05"

# --- Claude's public value (from Discord) ---
CLAUDE_PUBLIC="0xB769D5BE23AAD1A9"

echo "🔐 Diffie-Hellman Key Exchange"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Public parameters:"
echo "  Prime (p):            $P"
echo "  Generator (g):        $G"
echo "  Claude's public (A):  $CLAUDE_PUBLIC"
echo ""

# --- Generate your private key ---
echo "🔑 Generating your private key..."
PRIVATE_KEY=$(openssl rand -hex 8)
PRIVATE_KEY_DEC=$((16#$PRIVATE_KEY))
echo "  Your private key saved (keep secret!)"

# --- Compute your public value: g^private mod p ---
# Using python3/node for big int modular exponentiation
compute_public() {
    if command -v python3 &>/dev/null; then
        python3 -c "
p = $P
g = $G
priv = 0x$PRIVATE_KEY
pub = pow(g, priv, p)
print(hex(pub))
"
    elif command -v node &>/dev/null; then
        node -e "
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
const priv = 0x${PRIVATE_KEY}n;
const pub = modPow(g, priv, p);
console.log('0x' + pub.toString(16));
"
    else
        echo "ERROR: Need python3 or node installed"
        exit 1
    fi
}

YOUR_PUBLIC=$(compute_public)

# --- Compute shared secret: claude_public^private mod p ---
compute_shared() {
    if command -v python3 &>/dev/null; then
        python3 -c "
p = $P
claude_pub = $CLAUDE_PUBLIC
priv = 0x$PRIVATE_KEY
shared = pow(claude_pub, priv, p)
print(hex(shared))
"
    elif command -v node &>/dev/null; then
        node -e "
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
const claudePub = ${CLAUDE_PUBLIC}n;
const priv = 0x${PRIVATE_KEY}n;
const shared = modPow(claudePub, priv, p);
console.log('0x' + shared.toString(16));
"
    else
        echo "ERROR: Need python3 or node installed"
        exit 1
    fi
}

SHARED_SECRET=$(compute_shared)

# --- Derive AES key from shared secret ---
AES_KEY=$(echo -n "$SHARED_SECRET" | openssl dgst -sha256 | awk '{print $NF}')

# --- Save everything ---
SAVE_DIR="$HOME/.dh_exchange"
mkdir -p "$SAVE_DIR"
chmod 700 "$SAVE_DIR"

echo "$PRIVATE_KEY" > "$SAVE_DIR/private_key.hex"
echo "$YOUR_PUBLIC" > "$SAVE_DIR/public_value.hex"
echo "$SHARED_SECRET" > "$SAVE_DIR/shared_secret.hex"
echo "$AES_KEY" > "$SAVE_DIR/aes_key.hex"
chmod 600 "$SAVE_DIR"/*

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Keys generated and saved to $SAVE_DIR"
echo ""
echo "📤 YOUR PUBLIC VALUE (send this to Claude in Discord):"
echo ""
echo "    $YOUR_PUBLIC"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Shared secret computed and saved"
echo "🔑 AES-256 key derived and ready"
echo ""
echo "👉 Next steps:"
echo "   1. Send your public value above to Claude in Discord"
echo "   2. Run ./dh_encrypt.sh to encrypt your GitHub token"
echo "   3. Paste the encrypted output in Discord"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
