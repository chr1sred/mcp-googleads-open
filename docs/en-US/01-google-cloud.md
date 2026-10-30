# 1. Google Cloud setup

Goal: a **project** with the Google Ads API enabled and an **OAuth client** the server will use for user sign-in. Estimated time: 15 minutes. **Cost: zero.**

> Decide on the server address first. On CapRover with wildcard DNS it is the **app name** + your root domain (e.g. app `google-ads-mcp` → `google-ads-mcp.yourdomain.com`). This address is part of the redirect URI.

## Cost: why it's free

| Item | Cost |
|---|---|
| Google Cloud project | Free |
| Google Ads API (Explorer level) | Free, up to 2,880 operations/day on real accounts |
| Consent screen + OAuth client | Free |
| Billing account | **Not required** |

> **Don't link billing** to the project and ignore the "Start free / US$300" banner. With no billing account, there is no way to be charged.

## 1.1 Project

1. Open the [Google Cloud Console](https://console.cloud.google.com/) with the account that accesses your Google Ads accounts (or the MCC).
2. **New project** → name (e.g. `mcp-google-ads`).
3. Note the **project ID**; it goes in `GOOGLE_PROJECT_ID`.

> If Google rejects a readable ID with "project ID is not available", use the auto-generated one. It works the same.

> **Google Workspace:** on company accounts the project is created inside the organization (e.g. `yourcompany.com`), and this cannot be changed later. This is recommended because of the **Internal** consent screen (see 1.3).

## 1.2 Google Ads API and access level

1. Enable the [Google Ads API](https://console.cloud.google.com/apis/library/googleads.googleapis.com) in the project. It starts at **Test** level, which only reaches test accounts.
2. On the API page, click **Access levels → Manage**.
3. Under **Upgrade access level → Explorer**, click **Apply for access**. Approval is usually **automatic, within seconds**.

| Level | Real accounts | Daily limit | Needed? |
|---|---|---|---|
| Test | ❌ | 15,000 (test only) | Not enough |
| **Explorer** | ✅ | 2,880 | **Yes, it's enough** |
| Basic | ✅ | 15,000 | Only for high volume; requires brand verification |
| Standard | ✅ | Unlimited | Manual audit |

> Since 2026-09-09 Google no longer requires a *developer token*: the access level lives on the Cloud project.

## 1.3 Consent screen (Google Auth Platform)

**APIs & Services → OAuth consent screen → Get started**:

1. **App information:** name (e.g. "Google Ads MCP") and support email.
2. **Audience:**

   | Type | When to use | Who can sign in | Login expires? |
   |---|---|---|---|
   | **Internal** (recommended) | Google Workspace account | Anyone in your organization | No |
   | External + Testing | Personal Gmail account | Only registered "test users" (up to 100) | Yes, every ~7 days |

3. **Contact information:** your email.
4. Accept the user data policy and click **Create**.

No need to register scopes: the server requests `openid`, `userinfo.email`, `userinfo.profile` and `adwords` at sign-in.

## 1.4 OAuth client

1. **Google Auth Platform → Clients → Create client**.
2. Type: **Web application**. Any name (e.g. `mcp-googleads-caprover`).
3. **Authorized redirect URIs**, exactly:

   ```
   https://google-ads-mcp.yourdomain.com/auth/callback
   ```

4. Leave "Use this client for an AI-powered agent" unticked.
5. **Create.**

> ⚠️ **The client secret is shown only once.** In the "OAuth client created" dialog, copy the **ID** and the **secret** (or download the JSON) **before clicking OK**. Keep them in a password manager, never in the repository. If you lose the secret, use **Add secret** on the client and disable the old one.

> MCP clients (Claude etc.) are **not** registered here. They register themselves on your server (dynamic client registration), and the server bridges to Google.

## 1.5 MCC account (optional)

If you reach client accounts through a **manager account (MCC)**, set `GOOGLE_ADS_LOGIN_CUSTOMER_ID` to the MCC ID, **digits only** (e.g. `1234567890`). The assistant can also pass `login_customer_id` per call; the per-call value takes precedence.

## Checklist

- [ ] `GOOGLE_PROJECT_ID` noted
- [ ] Google Ads API enabled at **Explorer** level
- [ ] Consent screen created (Internal, or External + test users)
- [ ] "Web application" OAuth client with redirect `https://YOUR-APP.YOUR-DOMAIN/auth/callback`
- [ ] Client ID and secret stored safely
- [ ] No billing account linked

Next: [2. Deploy on CapRover](02-caprover.md)
