#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <client-name>" >&2
  exit 1
fi

CLIENT="$1"
if [[ ! "$CLIENT" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Client name may contain only letters, numbers, underscores, and hyphens." >&2
  exit 1
fi

EASYRSA_DIR="/etc/openvpn/easy-rsa"
if [[ ! -f "$EASYRSA_DIR/pki/ca.crt" ]]; then
  echo "OpenVPN PKI was not created. Run setup-openvpn.sh first." >&2
  exit 1
fi

cd "$EASYRSA_DIR"
EASYRSA_BATCH=1 EASYRSA_REQ_CN="$CLIENT" ./easyrsa gen-req "$CLIENT" nopass
EASYRSA_BATCH=1 ./easyrsa sign-req client "$CLIENT"

OUTPUT="/root/${CLIENT}-$(date +%Y%m%d).ovpn"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

{
  cat "$SCRIPT_DIR/client-template.ovpn"
  echo
  echo "<ca>"
  cat "$EASYRSA_DIR/pki/ca.crt"
  echo "</ca>"
  echo "<cert>"
  sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' "$EASYRSA_DIR/pki/issued/$CLIENT.crt"
  echo "</cert>"
  echo "<key>"
  cat "$EASYRSA_DIR/pki/private/$CLIENT.key"
  echo "</key>"
  echo "<tls-auth>"
  cat "$EASYRSA_DIR/pki/ta.key"
  echo "</tls-auth>"
} > "$OUTPUT"

chmod 600 "$OUTPUT"
echo "Created $OUTPUT"
