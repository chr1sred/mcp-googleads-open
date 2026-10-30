"""Healthcheck do container: o endpoint /mcp exige token (401), então checamos
os metadados OAuth públicos, que respondem 200 quando o servidor está de pé."""

import os
import sys
import urllib.request

port = os.environ.get("PORT", "8080")
url = f"http://127.0.0.1:{port}/.well-known/oauth-protected-resource/mcp"

try:
    with urllib.request.urlopen(url, timeout=4) as resp:
        sys.exit(0 if resp.status == 200 else 1)
except Exception:
    sys.exit(1)
