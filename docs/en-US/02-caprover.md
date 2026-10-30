# 2. Deploy on CapRover

## 2.1 DNS

Create an **A** record for the subdomain (e.g. `gads-mcp.yourdomain.com`) pointing to the VPS IP. If you use Cloudflare, keep the orange proxy **off** until the certificate is issued.

## 2.2 Create the app

1. In the CapRover dashboard: **Apps → Create a New App**.
2. Name: `google-ads-mcp`.
3. Tick **Has Persistent Data** (this is what keeps OAuth logins).

## 2.3 App Configs

**Environment Variables** (*Bulk Edit* mode), based on [`.env.example`](../../.env.example):

```env
GOOGLE_PROJECT_ID=your-gcp-project
GOOGLE_ADS_MCP_OAUTH_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET=GOCSPX-...
GOOGLE_ADS_MCP_BASE_URL=https://gads-mcp.yourdomain.com
GOOGLE_ADS_MCP_JWT_SIGNING_KEY=...
GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY=...
GOOGLE_ADS_LOGIN_CUSTOMER_ID=
```

Generate both keys with:

```bash
python3 scripts/gen-secrets.py
```

**Persistent Directories**:

| Path in App | Label |
|---|---|
| `/data` | `google-ads-mcp-data` |

**Instance Count**: keep it at **1**. On-disk storage is not shared between instances.

Click **Save & Update**.

## 2.4 HTTP Settings

1. **Container HTTP Port**: `8080`.
2. **Connect New Domain**: `gads-mcp.yourdomain.com`.
3. **Enable HTTPS**, then **Force HTTPS by redirecting all HTTP traffic to HTTPS**.
4. **Edit Default Nginx Configurations**: inside the `location / { ... }` block, add the lines from [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf):

   ```nginx
   proxy_buffering off;
   proxy_cache off;
   proxy_read_timeout 3600s;
   proxy_send_timeout 3600s;
   chunked_transfer_encoding on;
   ```

   Without this, MCP streaming (SSE) responses may hang or drop.

5. **Save & Update**.

## 2.5 Deploy

Pick a method in the **Deployment** tab:

| Method | How |
|---|---|
| **GitHub (recommended)** | Method 3: repository `https://github.com/YOUR-USER/mcp-googleads-open`, branch `main` (or `master`), GitHub user + token. Optionally add CapRover's webhook to GitHub for automatic deploys on push. |
| **CLI** | From the repository folder: `caprover deploy -a google-ads-mcp` |
| **Tarball** | Pack the repository (`.tar`) and upload it in the dashboard |

CapRover reads `captain-definition`, builds the `Dockerfile` and starts the container.

## 2.6 Quick test

```bash
# Should return 200 with JSON (OAuth metadata)
curl https://gads-mcp.yourdomain.com/.well-known/oauth-protected-resource/mcp

# Should return 401 (protected endpoint: OK!)
curl -i https://gads-mcp.yourdomain.com/mcp
```

Check that the `resource` URL in the first command is `https://gads-mcp.yourdomain.com/mcp`. If it shows `localhost`, `GOOGLE_ADS_MCP_BASE_URL` was not applied.

## 2.7 Updating

1. Change `ARG GOOGLE_ADS_MCP_VERSION=` in the `Dockerfile`.
2. Push (or redeploy). Logins stay valid as long as the `/data` volume and both keys are kept.

Next: [3. Connect MCP clients](03-mcp-clients.md)
