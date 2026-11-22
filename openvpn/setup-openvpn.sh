#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
TUN_NETWORK="10.8.0.0"
FORWARD_INTERFACE="${FORWARD_INTERFACE:-eth0}"

if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

apt-get update
apt-get install -y openvpn easy-rsa iptables

mkdir -p /etc/openvpn/pki

if [[ ! -f /etc/openvpn/pki/ca.crt ]]; then
  mkdir -p /etc/openvpn/easy-rsa
  cp -a /usr/share/easy-rsa/. /etc/openvpn/easy-rsa/
  cd /etc/openvpn/easy-rsa
  ./easyrsa init-pki
  EASYRSA_BATCH=1 EASYRSA_REQ_CN="OpenVPN Server CA" ./easyrsa build-ca nopass
  EASYRSA_BATCH=1 EASYRSA_REQ_CN="server" ./easyrsa gen-req server nopass
  EASYRSA_BATCH=1 ./easyrsa sign-req server server
  ./easyrsa gen-diffie-hellman
  ./easyrsa gen-crl
  ./easyrsa gen-tls-auth

  cp -a pki/. /etc/openvpn/pki/
  chmod 600 /etc/openvpn/pki/private/*.key
  cp crl.pem /etc/openvpn/pki/crl.pem 2>/dev/null || cp pki/crl.pem /etc/openvpn/pki/crl.pem
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 0644 "$SCRIPT_DIR/server.conf" /etc/openvpn/server.conf

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
grep -qxF 'net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

iptables -t nat -C POSTROUTING -s "$TUN_NETWORK/24" -o "$FORWARD_INTERFACE" -j MASQUERADE 2>/dev/null ||
  iptables -t nat -A POSTROUTING -s "$TUN_NETWORK/24" -o "$FORWARD_INTERFACE" -j MASQUERADE
iptables -C FORWARD -i tun0 -s "$TUN_NETWORK/24" -j ACCEPT 2>/dev/null ||
  iptables -A FORWARD -i tun0 -s "$TUN_NETWORK/24" -j ACCEPT
iptables -C FORWARD -o tun0 -d "$TUN_NETWORK/24" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
  iptables -A FORWARD -o tun0 -d "$TUN_NETWORK/24" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

systemctl enable --now openvpn@server
systemctl status openvpn@server --no-pager
