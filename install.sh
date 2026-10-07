#!/bin/bash

set -e

echo "[*] Installing python3-venv..."
sudo apt install python3-venv -y

echo "[*] Creating virtual environment..."
python3 -m venv .venv

echo "[*] Installing dependencies..."
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

echo "[*] Verifying LIZ403..."
.venv/bin/python LIZ403.py --help

echo "[+] LIZ403 installed successfully!"
