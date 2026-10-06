# LIZ403

> Advanced Python-based 403 bypass tool with TLS fingerprint evasion, intelligent scoring, and a minimal CLI.

![Python](https://img.shields.io/badge/Python-3.9%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)

---

## Overview

**LIZ403** is a next-generation 403/401 bypass tool written in Python. Unlike existing tools that only mutate headers, verbs, and paths, LIZ403 combines those techniques with **TLS/JA4 fingerprint spoofing** via `curl_cffi` — a critical capability against modern WAFs like Cloudflare, Akamai, and AWS WAF that flag non-browser TLS handshakes.

The tool is built for pentesters and bug bounty hunters who need a fast, reliable, and easy-to-use bypass scanner without compiling Go binaries or configuring complex environments.

---

## Features

- 🔐 **TLS Fingerprint Evasion** — Mimics real Chrome TLS ClientHello (JA4) using `curl_cffi`
- 🎯 **Auto-Calibration** — Establishes baseline from non-existent paths to detect real bypasses
- 🧠 **Intelligent Scoring Engine** — Ranks results by status shift, length delta, body hash, and Location changes
- 🔀 **Comprehensive Mutation Engine** — HTTP verbs, verb case, IP-trust headers, rewrite headers, path prefixes/suffixes, encodings, host override, method override
- ⚡ **Async Execution** — Fast sequential probing with optional delay to evade rate limiting
- 🧩 **Simple CLI** — One-line usage: `python LIZ403.py -u <URL>`
- 📋 **Reproducible Output** — Copy-paste ready results with scoring and reasoning
- 🪶 **Minimal Dependencies** — Only `curl_cffi` required

---

## Why LIZ403?

| Feature | nomore403 (Go) | LIZ403 (Python) |
|---------|----------------|-----------------|
| Language | Go 1.24+ | Python 3.9+ |
| **TLS fingerprint spoofing** | ❌ None | ✅ `curl_cffi` (Chrome JA4) |
| Auto-calibration | ✅ | ✅ |
| Scoring engine | ✅ | ✅ |
| Method mutation | ✅ | ✅ |
| Header injection | ✅ | ✅ |
| Path mutation | ✅ | ✅ |
| Ease of use | Requires Go build | `pip install` and run |
| Extensibility | Edit Go payloads | Edit Python lists |

**LIZ403's edge:** TLS-fingerprint-level bypass capability inside the Python ecosystem, where no equally mature solution exists natively.

---

## Installation

### Requirements

- Python 3.9 or higher
- Linux, macOS, or Windows (WSL2 recommended)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/71ZK1/LIZ403.git
cd LIZ403

# 2. Create a virtual environment (recommended)
python3 -m venv liz403-env
source liz403-env/bin/activate     # Linux/macOS
# liz403-env\Scripts\activate      # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Verify installation
python LIZ403.py --help
