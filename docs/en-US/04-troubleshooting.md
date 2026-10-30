# 4. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Error 400: redirect_uri_mismatch` on Google sign-in | Redirect URI differs from the registered one | Register exactly `https://YOUR-DOMAIN/auth/callback` (https, no trailing slash) in the OAuth client |
| `Access blocked: app has not completed verification` | Your email is not a test user | Add it under **Test users** on the consent screen |
| Metadata shows `localhost:8080` | `GOOGLE_ADS_MCP_BASE_URL` missing or wrong | Set the public URL and *Save & Update* |
| Must sign in again every week | External OAuth app in **Testing** mode (~7-day refresh token) | On Google Workspace, use an **Internal** consent screen (no expiry). On Gmail, this is expected |
| Must sign in again after every deploy | `/data` not persistent, or keys changed | Enable *Has Persistent Data*, map `/data`, keep `JWT_SIGNING_KEY` and `STORAGE_ENCRYPTION_KEY` fixed |
| Connection hangs or drops mid-response | nginx buffering SSE | Apply [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf) |
| `USER_PERMISSION_DENIED` / account not accessible | MCC access without `login-customer-id` | Set `GOOGLE_ADS_LOGIN_CUSTOMER_ID` (digits only) or name the MCC in the prompt |
| `The developer token is only approved for use with test accounts` | Insufficient access level | Apply for Explorer/Basic on the project's Google Ads API page |
| Container restarts in a loop | Missing required variable or invalid key | Check the app logs in CapRover; regenerate keys with `scripts/gen-secrets.py` |
| CapRover Method 3 won't save (no webhook, "Force build" disabled) | Empty username/password | Use your GitHub username + a classic token **with no scopes** (public repository) |
| "Privacy error" in the browser before deploying | No certificate for the app yet (`.app` domains force HTTPS) | Click **Enable HTTPS** on the CapRover app |
| Lost the client secret | Google shows the secret only once | On the OAuth client: **Add secret**, update CapRover, disable the old one |
| Readable project ID rejected ("not available") | IDs are globally unique | Use the auto-generated ID |
| `/mcp` returns **401** in browser/curl | Correct behavior | The endpoint requires a token; use an MCP client |

## Useful commands

```bash
# Metadata (must return 200)
curl https://YOUR-DOMAIN/.well-known/oauth-protected-resource/mcp
curl https://YOUR-DOMAIN/.well-known/oauth-authorization-server

# Service logs on the CapRover host
docker service logs srv-captain--google-ads-mcp --tail 100 -f
```

## Reporting issues

- Deployment/documentation issues with this project: open an *issue* here.
- Issues with the MCP server itself (tools, queries): [googleads/google-ads-mcp/issues](https://github.com/googleads/google-ads-mcp/issues).
