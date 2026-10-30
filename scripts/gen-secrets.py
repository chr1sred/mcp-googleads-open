#!/usr/bin/env python3
"""Gera as chaves secretas do servidor / Generates the server secrets.

Uso / Usage:  python3 scripts/gen-secrets.py
"""

import base64
import secrets

jwt_key = secrets.token_urlsafe(48)
# Chave Fernet válida: 32 bytes em base64 url-safe
fernet_key = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode()

print(f"GOOGLE_ADS_MCP_JWT_SIGNING_KEY={jwt_key}")
print(f"GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY={fernet_key}")
print()
print("Guarde estes valores. Se mudarem, todos os logins OAuth precisam ser refeitos.")
print("Keep these values safe. If they change, every OAuth login must be redone.")
