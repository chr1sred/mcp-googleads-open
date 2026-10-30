# mcp-googleads-open

[🇧🇷 Português](README.md) | 🇺🇸 English

**Self-hosted** deployment of the [official Google Ads MCP server](https://github.com/googleads/google-ads-mcp) on a VPS with **CapRover** (or Docker Compose), with HTTPS, OAuth login and persistent, encrypted tokens.

It lets MCP-compatible AI assistants (Claude, Claude Code, Codex, Cursor, Antigravity, etc.) query your Google Ads accounts in natural language: *"How did my campaigns perform this week?"*.

> This project **does not modify** Google's server. It packages the official release published on PyPI, pinned in the `Dockerfile`, and adds everything needed to run it in production on your own VPS.

## Why self-hosted?

| | Local (stdio, Google default) | Cloud Run (official guide) | **This project (VPS + CapRover)** |
|---|---|---|---|
| Runs on | Your computer | Google Cloud | Your VPS |
| Shared across devices/agents | ❌ | ✅ | ✅ |
| Works as a remote connector in Claude | ❌ | ✅ | ✅ |
| Credentials kept out of client config | ❌ | ✅ | ✅ |
| Cost | Free | Pay-per-use + Firestore/Redis | Already covered by your VPS |
| Login persistence | n/a | Firestore or Redis | Encrypted on-disk volume |

## What the server does

**Read-only** mode (current Google release):

| Tool | Purpose |
|---|---|
| `customers_list_accessible_customers` | Lists the accounts your login can access |
| `search_search` | Queries data via GAQL (campaigns, metrics, budgets, status) |
| `metadata_get_resource_metadata` | Shows the fields available for a resource (e.g. `campaign`) |

It also exposes the discovery document, metrics, segments and release notes of the Google Ads API as *resources*.

## Architecture

```
MCP client (Claude, Claude Code...)
        │  HTTPS  /mcp  (OAuth 2.1 + dynamic client registration)
        ▼
CapRover (nginx + Let's Encrypt)
        │  HTTP 8080
        ▼
google-ads-mcp container (FastMCP OAuth Proxy)
        │  /data volume → encrypted OAuth tokens
        ▼
Google OAuth  +  Google Ads API
```

Each person signs in with their own Google account and only sees the Google Ads accounts they already have access to.

## Requirements

- VPS running CapRover (reference: 3 vCPU, 3 GB RAM + swap; the process uses ~170 MB)
- A subdomain pointing to the VPS (on CapRover with wildcard DNS, it is simply the app name: `google-ads-mcp.yourdomain.com`)
- A Google Cloud project with the **Google Ads API** enabled at **Explorer** level (free, no billing)
- A Google account with access to the Google Ads accounts (directly or through an MCC)

## Quick start

1. **Google Cloud** → create the OAuth client and consent screen: [docs/en-US/01-google-cloud.md](docs/en-US/01-google-cloud.md)
2. **Secrets** → `python3 scripts/gen-secrets.py`
3. **CapRover** → app, volume, env vars, domain and nginx tweak: [docs/en-US/02-caprover.md](docs/en-US/02-caprover.md)
4. **MCP clients** → connect Claude, Claude Code and others to `https://YOUR-DOMAIN/mcp`: [docs/en-US/03-mcp-clients.md](docs/en-US/03-mcp-clients.md)
5. Issues? [docs/en-US/04-troubleshooting.md](docs/en-US/04-troubleshooting.md)

No CapRover? Use [`docker-compose.yml`](docker-compose.yml) behind any HTTPS reverse proxy (Traefik, Caddy, nginx).

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_PROJECT_ID` | ✅ | Google Cloud project ID |
| `GOOGLE_ADS_MCP_OAUTH_CLIENT_ID` | ✅ | OAuth client ID ("Web application" type) |
| `GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET` | ✅ | OAuth client secret |
| `GOOGLE_ADS_MCP_BASE_URL` | ✅ | Public URL, without `/mcp` and without a trailing slash |
| `GOOGLE_ADS_MCP_JWT_SIGNING_KEY` | ✅ | Fixed key so logins survive redeploys |
| `GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY` | ✅ | Encrypts tokens stored on disk |
| `GOOGLE_ADS_LOGIN_CUSTOMER_ID` | — | Default MCC ID (digits only) |
| `GOOGLE_ADS_DEVELOPER_TOKEN` | — | Sunset by Google in 09/2026; leave empty |
| `GOOGLE_ADS_MCP_TOOLS_CONFIG` | — | Path to a `tools_config.yaml` to enable/disable tools |

Full template in [`.env.example`](.env.example).

## Updating Google's server

Change `GOOGLE_ADS_MCP_VERSION` in the [`Dockerfile`](Dockerfile) to the desired [PyPI](https://pypi.org/project/google-ads-mcp/) version and redeploy. Logins are kept as long as the volume and keys stay the same.

## Security

- The endpoint is public, but **every call requires OAuth login**.
- Who can sign in is set in Google: an **Internal** consent screen (your Workspace organization only) or **External in Testing** (registered test users only).
- Tokens are encrypted (Fernet) in the `/data` volume. Never commit `.env` or credential JSON files.
- The container runs as a non-root user.

## Credits and license

- MCP server: [googleads/google-ads-mcp](https://github.com/googleads/google-ads-mcp), © Google LLC, Apache-2.0.
- This repository: Apache-2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE).

Independent project, not affiliated with Google. "Google Ads" is a trademark of Google LLC.
