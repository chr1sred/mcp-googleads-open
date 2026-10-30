# 2. Deploy on CapRover

## 2.1 Address (DNS)

| Your CapRover | What to do |
|---|---|
| **Wildcard DNS** (`*.yourdomain.com` → VPS), CapRover's default | Nothing. The app automatically gets `APP-NAME.yourdomain.com`. To use `google-ads-mcp.yourdomain.com`, just name the app `google-ads-mcp`. |
| Domain outside the wildcard | Create an **A** record pointing to the VPS IP and use **Connect New Domain** (step 2.4). With Cloudflare, keep the orange proxy off until the certificate is issued. |

> Use **the same address** in three places: Google redirect URI, `GOOGLE_ADS_MCP_BASE_URL`, and the MCP clients' URL.

## 2.2 Create the app

1. **Apps → Create a New App**.
2. Tick **Has Persistent Data** (this is what keeps OAuth logins).
3. Name: `google-ads-mcp` → **Create New App**.

## 2.3 App Configs

**Environment Variables** (turn on *Bulk Edit*):

```env
GOOGLE_PROJECT_ID=your-gcp-project
GOOGLE_ADS_MCP_BASE_URL=https://google-ads-mcp.yourdomain.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET=GOCSPX-...
GOOGLE_ADS_MCP_JWT_SIGNING_KEY=...
GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY=...
```

No spaces around `=`, no quotes. Optional: `GOOGLE_ADS_LOGIN_CUSTOMER_ID=` (MCC ID, digits only).

Generate both keys on your computer (no need to clone the repository):

```bash
python3 -c "import secrets,base64;print('GOOGLE_ADS_MCP_JWT_SIGNING_KEY='+secrets.token_urlsafe(48));print('GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY='+base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())"
```

Keep the keys together with the client secret. If they change, every login must be redone.

**Persistent Directories** → Add:

| Path in App | Label |
|---|---|
| `/data` | `google-ads-mcp-data` |

**Instance Count:** keep it at **1** (on-disk storage is not shared).

**Save & Update.**

## 2.4 HTTP Settings

1. **Enable HTTPS** (issues the Let's Encrypt certificate immediately).
2. **Container HTTP Port:** `8080`.
3. Tick **Force HTTPS by redirecting all HTTP traffic to HTTPS**.
4. **Edit Default Nginx Configurations.** The template has **two** `location /` blocks. Use the **second** one (the one with `proxy_pass $upstream;`) and paste the lines from [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf) **right below** `proxy_set_header X-Forwarded-Proto $scheme;`:

   ```nginx
   proxy_buffering off;
   proxy_cache off;
   proxy_read_timeout 3600s;
   proxy_send_timeout 3600s;
   chunked_transfer_encoding on;
   ```

   Don't touch the `<% ... %>` areas. Without these lines, MCP streaming (SSE) responses may hang.

5. Leave **Websocket Support** off (MCP doesn't use it).
6. **Save & Update.**

## 2.5 Deploy

### Method 6: prebuilt image (fastest)

**Deployment tab → Method 6: Deploy via ImageName** → `ghcr.io/chr1sred/mcp-googleads-open:1.0.0` → **Deploy Now**.

No build on the VPS, no token. To update, change the version and deploy again. Prefer a pinned version (`1.0.0`) over `latest`, so you know exactly what is running.

### Method 3: GitHub (build on the VPS)

> ⚠️ CapRover **does not save** Method 3 with empty username and password, **even for a public repository**. A token is required.

1. On GitHub: **Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token**.
   - **Don't tick any scope.** For a public repository, a token with no scopes can clone and has no write permission anywhere.
   - Expiration: 90 days (renew later).
2. In CapRover, **Deployment tab → Method 3**:

   | Field | Value |
   |---|---|
   | Repository | `github.com/YOUR-USER/mcp-googleads-open` |
   | Branch | `main` (or any branch you like) |
   | Username | your GitHub username |
   | Password | the token |

3. **Save & Update.** The webhook appears and the **Force build** button becomes available.
4. **Force build.** The first build takes 2–4 minutes. Follow it in **View Build Logs**.
5. Optional: add CapRover's webhook on GitHub (Settings → Webhooks) for automatic redeploys on every push.

### Other methods

| Method | When to use |
|---|---|
| Method 3 (above) | You forked the repo and want automatic deploys on every push |
| CLI (`caprover deploy -a google-ads-mcp`) | You already use the CapRover CLI |
| Tarball | No token: download the ZIP from GitHub, convert to `.tar` and upload |

## 2.6 Quick test

```bash
# 200 with JSON (OAuth metadata)
curl https://google-ads-mcp.yourdomain.com/.well-known/oauth-protected-resource/mcp

# 401 = protected endpoint: OK!
curl -i -X POST https://google-ads-mcp.yourdomain.com/mcp
```

The `resource` field in the first command must be `https://google-ads-mcp.yourdomain.com/mcp`. If it shows `localhost`, `GOOGLE_ADS_MCP_BASE_URL` was not applied.

> Opening `/mcp` in a browser shows an error page: that's the expected 401, not a problem.

## 2.7 Updating

1. Change `ARG GOOGLE_ADS_MCP_VERSION=` in the `Dockerfile` and push (or **Force build**).
2. Logins stay valid as long as the `/data` volume and both keys are kept.

## 2.8 Rotating secrets

1. Generate new keys with the command from step 2.3.
2. In Google Cloud, on the OAuth client: **Add secret** → copy the new one → disable and delete the old one.
3. Update the 3 variables in CapRover → **Save & Update**. Users must sign in again.

Next: [3. Connect MCP clients](03-mcp-clients.md)
