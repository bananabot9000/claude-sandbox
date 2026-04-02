#!/bin/sh
set -e

# --- Helpers ---
usage() {
  echo "Usage: $(basename "$0") <command>"
  echo ""
  echo "Commands:"
  echo "  --generate     Generate a new GPG key (interactive)"
  echo "  --test-sign    Test signing with a key (prompts for email)"
  exit 1
}

find_key_by_email() {
  email="$1"
  gpg --list-secret-keys --keyid-format long "$email" 2>/dev/null \
    | grep -m1 'sec' \
    | sed 's/.*\/\([A-F0-9]\{16\}\).*/\1/'
}

generate_key() {
  gpg --full-generate-key

  echo ""
  echo "Your keys:"
  gpg --list-secret-keys --keyid-format long
}

test_sign() {
  printf "Email: "
  read -r email

  if [ -z "$email" ]; then
    echo "Error: email is required"
    exit 1
  fi

  key_id=$(find_key_by_email "$email")

  if [ -z "$key_id" ]; then
    echo "Error: no key found for $email"
    exit 1
  fi

  echo "Testing sign with key $key_id ($email)..."
  echo "banana" | gpg --local-user "$key_id" --clearsign > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "Signing works."
  else
    echo "Signing failed."
    exit 1
  fi
}

# --- Main ---
case "${1:-}" in
  --generate)  generate_key ;;
  --test-sign) test_sign ;;
  *)           usage ;;
esac
