# 3. Connect MCP clients

Server URL for every client:

```
https://google-ads-mcp.yourdomain.com/mcp
```

No secrets go into the client configuration. On first use, the client opens the browser so you can sign in with your Google account. With an **Internal** consent screen, any account in your organization can sign in; with **External + Testing**, only registered test users.

| Client | How to add | Status |
|---|---|---|
| Claude (web/desktop/mobile) | Custom connector with the URL above | ✅ tested |
| Claude Code | `claude mcp add --transport http google-ads https://google-ads-mcp.yourdomain.com/mcp`, then `/mcp` to authenticate | 🔄 to be validated |
| Codex CLI | `codex mcp add google_ads --url https://google-ads-mcp.yourdomain.com/mcp` and `codex mcp login google_ads` | 📄 documented by Google |
| Antigravity | `"serverUrl": "https://google-ads-mcp.yourdomain.com/mcp"` under `mcpServers` | 📄 documented by Google |
| Cursor / VS Code | HTTP-type MCP server with the URL above | 🔄 to be validated |
| n8n | *MCP Client Tool* node (HTTP Streamable) | 🔄 to be validated |

*(The Status column will be updated as real-world tests are completed.)*

## Claude

1. Add a **custom connector** with the URL `https://google-ads-mcp.yourdomain.com/mcp`.
2. Click connect. You'll be taken to Google's consent screen.
3. Authorize and return to Claude. The Google Ads tools then show up in the conversation.

## Claude Code

```bash
claude mcp add --transport http google-ads https://google-ads-mcp.yourdomain.com/mcp
```

Inside Claude Code, run `/mcp`, pick `google-ads` and finish the sign-in in the browser.

## Prompts to try

```
Which Google Ads accounts can I access?
How many active campaigns does account 123-456-7890 have?
How did campaigns in account 1234567890 perform over the last 7 days?
Which fields can I query on the "campaign" resource?
```

Tip: include the **account ID** in the prompt when working with several accounts. If access is through an MCC, make sure `GOOGLE_ADS_LOGIN_CUSTOMER_ID` is set, or ask the assistant to use the MCC as `login_customer_id`.

Next: [4. Troubleshooting](04-troubleshooting.md)
