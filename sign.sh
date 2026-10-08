#!/bin/bash
#
# Creates an LZMA compressed Fido.ps1 (including decompressed size) and sign it
#
# Linux port by AI by BENDER (under opencode)
#
# This script runs on Linux as well as on MSYS2/Git Bash on Windows:
#
#   * The RSA signature of the LZMA payload (Fido.ps1.lzma.sig) is created with openssl.
#   * The Authenticode signature of Fido.ps1 itself can only be applied on Windows, since it
#     requires the Windows SDK signtool and the Akeo EV certificate. When signtool is not
#     available the step is skipped with a notice instead of failing.
#
# The keys can be overridden from the environment:
#
#   PRIVATE_KEY=/path/to/private.pem PUBLIC_KEY=/path/to/public.pem ./sign.sh
#
set -euo pipefail

PRIVATE_KEY=${PRIVATE_KEY:-/d/Secured/Akeo/Rufus/private.pem}
PUBLIC_KEY=${PUBLIC_KEY:-/d/Secured/Akeo/Rufus/public.pem}
SIGNTOOL=${SIGNTOOL:-C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool}
SHA1_THUMBPRINT=${SHA1_THUMBPRINT:-fc4686753937a93fdcd48c2bb4375e239af92dcb}
FILE=Fido.ps1
LZMA_FILE=Fido.ps1.lzma
PASSWORD=""

die() {
  echo "Error: $*" >&2
  exit 1
}

# GNU and BSD stat do not agree on how to get the size of a file
file_size() {
  if stat -c%s "$1" >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f %z "$1"
  fi
}

# Create or update the RSA signature of a file, then verify it
sign_file() {
  local target=$1
  if [ -f "$target.sig" ] &&
     openssl dgst -sha256 -verify "$PUBLIC_KEY" -signature "$target.sig" "$target" >/dev/null 2>&1; then
    echo "Signature for $target is already up to date"
    return 0
  fi
  if [ -f "$target.sig" ]; then
    echo "Updating signature for $target"
  else
    echo "Creating signature for $target"
  fi
  openssl dgst -sha256 -sign "$PRIVATE_KEY" -passin pass:"$PASSWORD" -out "$target.sig" "$target"
  openssl dgst -sha256 -verify "$PUBLIC_KEY" -signature "$target.sig" "$target" >/dev/null
  echo "Signature for $target created and verified"
}

[ -f "$FILE" ] || die "$FILE not found - run this script from the root of the repository"
[ -f "$PRIVATE_KEY" ] || die "private key '$PRIVATE_KEY' not found (set PRIVATE_KEY=...)"
[ -f "$PUBLIC_KEY" ] || die "public key '$PUBLIC_KEY' not found (set PUBLIC_KEY=...)"
PRIVATE_KEY=$(realpath "$PRIVATE_KEY")
PUBLIC_KEY=$(realpath "$PUBLIC_KEY")

# Update the Authenticode signature (Windows only). Note that a random 'signtool' from $PATH
# must not be picked up on Linux, where it would be a completely different tool.
SIGNTOOL_BIN=""
if [ -f "$SIGNTOOL" ]; then
  SIGNTOOL_BIN=$SIGNTOOL
elif [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]] &&
     command -v signtool >/dev/null 2>&1; then
  SIGNTOOL_BIN=signtool
fi
if [ -n "$SIGNTOOL_BIN" ]; then
  MSYS2_ARG_CONV_EXCL='*' "$SIGNTOOL_BIN" sign /v /sha1 "$SHA1_THUMBPRINT" /fd SHA256 \
    /tr http://timestamp.digicert.com /td SHA256 "$FILE"
else
  echo "Note: signtool is not available - skipping the Authenticode signature of $FILE (Windows only)"
fi

# Ask for the pass phrase of the private key and confirm that it is valid
read -r -s -p "Enter pass phrase for $(realpath "$PRIVATE_KEY"): " PASSWORD ||
  { echo; die "no pass phrase supplied"; }
echo
openssl pkey -in "$PRIVATE_KEY" -passin pass:"$PASSWORD" -noout >/dev/null 2>&1 ||
  { echo "Invalid pass phrase"; exit 1; }

# Create the LZMA archive
if command -v lzma >/dev/null 2>&1; then
  lzma -kf "$FILE"
else
  command -v xz >/dev/null 2>&1 || die "neither lzma nor xz is available"
  xz --format=lzma -kf "$FILE"
fi

# The 'lzma' utility does not add the uncompressed size, so we must add it manually. And yes, this whole
# gymkhana is what one must actually go through to insert a 64-bit little endian size into a binary file...
printf "00: %016X" "$(file_size "$FILE")" | xxd -r | xxd -p -c1 | tac | xxd -p -r |
  dd of="$LZMA_FILE" seek=5 bs=1 status=none conv=notrunc

# Make sure that the size we just wrote is the one that can actually be read back
UNCOMPRESSED_SIZE=$(od -An -tu8 -j5 -N8 "$LZMA_FILE" | tr -d ' \n')
[ "$UNCOMPRESSED_SIZE" = "$(file_size "$FILE")" ] ||
  die "could not insert the uncompressed size into $LZMA_FILE (read $UNCOMPRESSED_SIZE, expected $(file_size "$FILE"))"

sign_file "$LZMA_FILE"

# Clear the PASSWORD variable just in case
unset PASSWORD
