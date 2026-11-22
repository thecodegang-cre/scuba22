# Password Generator

A simple Python password generator that creates secure random passwords.

## Features

- Custom password length
- Includes letters, numbers, and symbols
- Lightweight and easy to use

## Usage

```bash
python password_generator.py
```

## Example

Enter password length: 16

Generated Password:
A$8k!P2@zQ#1LmN%

# OpenVPN Server

The `openvpn/` directory contains scripts for a Linux OpenVPN server using
WireGuard-free OpenVPN UDP on port `1194`.

Run the setup with root privileges:

```bash
sudo openvpn/setup-openvpn.sh
```

Create a client profile:

```bash
sudo openvpn/add-client.sh laptop
```

The generated profile is saved in `/root/laptop-YYYYMMDD.ovpn` with mode
`0600`. Generated profiles, certificates, keys, and PEM files are ignored by
Git.
