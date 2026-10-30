---
name: google-ads-analyst
description: Analyze Google Ads accounts through the Google Ads MCP server (googleads/google-ads-mcp, e.g. deployed with mcp-googleads-open). Use whenever the user asks about Google Ads performance, campaigns, spend, conversions, keywords, search terms, budgets, impression share, devices, locations, ads or recent account changes, or wants a Google Ads report or account audit. Covers MCC discovery, validated GAQL recipes, unit conversion and a report format in Portuguese or English.
---

# Google Ads Analyst

Turn the read-only Google Ads MCP tools into accurate, client-ready analysis.

## Tools you will use

The connector exposes three tools. Hosts may add a prefix (e.g. `customers_list_accessible_customers`, `search_search`, `metadata_get_resource_metadata`):

| Tool | Use it for |
|---|---|
| `list_accessible_customers` | IDs the signed-in user can reach directly (no names) |
| `search` | Every query: `customer_id`, `resource`, `fields`, `conditions`, `orderings`, `limit`, `login_customer_id` |
| `get_resource_metadata` | Field discovery when a field is **not** in the recipes |

The server is **read-only**. Never promise to pause, edit or create anything; give the user the exact steps to do it in the Google Ads UI instead.

## Workflow

### 1. Find the account (cheapest path first)

1. If the user gave an account ID (`123-456-7890`), strip the hyphens and use it.
2. Otherwise call `list_accessible_customers`, then find the **manager (MCC)** accounts: query `customer` (recipe R1) on the returned IDs until you find ones with `customer.manager = true`. Stop as soon as you find the MCC the user works with.
3. On the MCC, run recipe **R2** (`customer_client`): **one operation** returns every child account with name, currency and status. Prefer this over querying accounts one by one.
4. Match the user's words ("a conta da padaria") to `descriptive_name`. If several match, ask.
5. For a child account reached through an MCC, pass the MCC ID as `login_customer_id` on every call.

Skip `CANCELED`/`SUSPENDED` accounts unless asked; they return *"customer account can't be accessed"*. Report that plainly instead of retrying.

### 2. Pin the period

- Always use explicit dates: `segments.date BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'`. Never pass relative words.
- Default to the **last full 30 days ending yesterday**. Today's data is incomplete.
- For "this month vs last month" or "week over week", run the same query twice with the two ranges and compare.
- State the period in every answer.

### 3. Query with the recipes

Use the validated queries in [references/gaql-recipes.md](references/gaql-recipes.md). They cover:

| # | Question | Resource |
|---|---|---|
| R1 | Is this a manager account? Name, currency | `customer` |
| R2 | All accounts under an MCC | `customer_client` |
| R3 | Campaign performance | `campaign` |
| R4 | Daily trend | `customer` + `segments.date` |
| R5 | Budget and lost impression share | `campaign` + `campaign_budget` |
| R6 | Ad group performance | `ad_group` |
| R7 | Keywords and Quality Score | `keyword_view` |
| R8 | Search terms (negatives, opportunities) | `search_term_view` |
| R9 | Conversions by action | `customer` + `segments.conversion_action_name` |
| R10 | Device split | `customer` + `segments.device` |
| R11 | Locations (with names) | `geographic_view` → `geo_target_constant` |
| R12 | Responsive search ads and Ad Strength | `ad_group_ad` |
| R13 | Who changed what (last 30 days) | `change_event` |

If a needed field is not there, call `get_resource_metadata` for that resource. **Do not guess field names.** Wrong fields fail the call and waste quota.

### 4. Convert the raw values (mandatory)

| Raw value | Show as |
|---|---|
| `*_micros` (cost, CPC, CPA, budget) | divide by **1,000,000**, in the account `currency_code` |
| `ctr`, `*_impression_share`, `*_lost_impression_share` | multiply by 100 → **%** |
| `conversions` (fractional, data-driven attribution) | 1 decimal place |
| `quality_score = 0` | **"sem nota" / "no score"**, never "0/10" |
| Impression share on non-Search campaigns (Demand Gen, Video, Display, PMax) | **N/A**, since the API returns 0 there |
| `ad_strength = UNSPECIFIED` | not applicable (non-RSA ads) |
| Video campaigns with 0 clicks | normal: they buy views/impressions, so judge them by CPM and conversions |

Compute derived metrics yourself and label them: CPA = cost ÷ conversions, CPC = cost ÷ clicks, conversion rate = conversions ÷ clicks, CPM = cost ÷ impressions × 1000. Guard against division by zero.

### 5. Respect the quota

The Explorer access level allows **2,880 operations/day** on real accounts, and every `search` call counts.

- Prefer one wide query (`customer_client`, segmented queries) over many narrow ones.
- Use `limit` on ranked lists (top 10–20). Add `metrics.impressions > 0` to drop zero rows.
- Do not re-run identical queries in the same conversation. Reuse the results.

## Report format

Answer in the **user's language** (PT-BR by default for Portuguese speakers). For a performance report:

1. **Header**: account name, ID, period, currency.
2. **Resumo / Summary**: 3–5 bullets with the key numbers and the single most important insight.
3. **Table**: one row per campaign (name, type, spend, conversions, CPA, CTR or CPM), sorted by spend, with a totals row.
4. **Destaques / Highlights**: what is working, backed by numbers.
5. **Pontos de atenção / Watch-outs**: lost impression share by budget > 20%, CPA well above account average, keywords without score or with QS ≤ 5, search terms with spend and zero conversions, disapproved ads.
6. **Próximos passos / Next steps**: concrete actions the user can take in the Google Ads UI (the server can't make changes).

Rules:

- Never invent numbers. Every figure must come from a query in this conversation.
- When comparing periods, show absolute values **and** % change.
- Keep names exactly as in the account (campaign naming conventions carry meaning).
- If a query fails, say which data is missing and continue with the rest.

## Example

User: *"Como foi a Padaria Exemplo nos últimos 30 dias?"*

1. R2 on the MCC → `Padaria Exemplo` = `1234567890`, BRL.
2. R3 + R9 + R5 for the last 30 full days, with `login_customer_id` = the MCC.
3. Report: total spend and leads, CPA per campaign, a Search campaign losing most of its impression share to budget as the main watch-out, and the top search terms.
