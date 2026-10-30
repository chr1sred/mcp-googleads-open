# 1. Google Cloud setup

Goal: a **project** with the Google Ads API enabled and an **OAuth client** the server will use for user sign-in.

> Decide on the server subdomain first (e.g. `gads-mcp.yourdomain.com`). It is part of the redirect URI.

## 1.1 Project and API

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create (or pick) a project. Note the **project ID**; it goes in `GOOGLE_PROJECT_ID`.
2. Enable the [Google Ads API](https://console.cloud.google.com/apis/library/googleads.googleapis.com).
3. On the Google Ads API overview page, check the project's **access level**: Explorer, Basic or Standard. If none is set, apply for one.

> Since 2026-09-09 Google no longer requires a *developer token*: the access level is tied to the Cloud project.

## 1.2 OAuth consent screen (Google Auth Platform)

1. **APIs & Services → OAuth consent screen** (or **Google Auth Platform**).
2. User type: **External**. If you use Google Workspace and all users belong to the same organization, **Internal** also works.
3. Fill in the app name (e.g. "Google Ads MCP") and support/contact emails.
4. **Scopes**: you don't need to register them here; the server requests `openid`, `userinfo.email`, `userinfo.profile` and `https://www.googleapis.com/auth/adwords` at sign-in.
5. **Publishing status: Testing.** Under **Test users**, add every email that will use the server.

### Testing vs Production

| | Testing (recommended for personal/agency use) | Production |
|---|---|---|
| Who can sign in | Only registered test users (up to 100) | Any Google account |
| Login lifetime | Google expires the refresh token after ~7 days: sign in again weekly | No forced expiry |
| Google verification | Not required | The `adwords` scope requires app verification |

## 1.3 OAuth client

1. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
2. Application type: **Web application**.
3. **Authorized redirect URIs**: add exactly

   ```
   https://gads-mcp.yourdomain.com/auth/callback
   ```

4. Save and copy the **Client ID** and **Client secret** into `GOOGLE_ADS_MCP_OAUTH_CLIENT_ID` and `GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET`.

> MCP clients (Claude etc.) do **not** need to be registered here. They register themselves on your server via dynamic client registration (DCR), and the server bridges to Google.

## 1.4 MCC account (optional)

If you reach client accounts through a **manager account (MCC)**, set `GOOGLE_ADS_LOGIN_CUSTOMER_ID` to the MCC ID, **digits only** (e.g. `1234567890`). The assistant can also pass `login_customer_id` per call; the per-call value takes precedence.

## Checklist

- [ ] `GOOGLE_PROJECT_ID` noted
- [ ] Google Ads API enabled with an approved access level
- [ ] Consent screen in **Testing** with your emails as test users
- [ ] "Web application" OAuth client with redirect `https://YOUR-DOMAIN/auth/callback`
- [ ] Client ID and secret stored safely

Next: [2. Deploy on CapRover](02-caprover.md)
