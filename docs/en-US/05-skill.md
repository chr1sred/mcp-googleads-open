# 5. `google-ads-analyst` skill for Claude

The MCP server gives Claude **access** to the accounts (the "hands"). The skill teaches Claude **how** to analyze them well (the "manual").

| | Without the skill | With the skill |
|---|---|---|
| Finding the account | Queries accounts one by one | Finds the MCC and lists everything in **1 operation** |
| GAQL queries | Guesses fields, burns quota on errors | Uses **13 recipes validated** on a live account |
| Values | May show cost in *micros* or QS "0" | Converts currency, %, "no score", N/A |
| Report | Free-form | Summary, table, highlights, watch-outs and next steps, in English or Portuguese |
| Quota (2,880/day) | No care | Wide queries, `limit`, no repeats |

## Requirements

- This project's connector already working (guides 1–3).
- Claude on **Pro, Max, Team or Enterprise**, with **code execution** enabled.

## Installation

1. Download **`google-ads-analyst.zip`** from the [latest release](https://github.com/chr1sred/mcp-googleads-open/releases/latest).
2. In Claude: **Settings → Capabilities → Skills → Upload skill** and upload the ZIP.
3. Enable the skill and make sure the Google Ads connector is also enabled in the conversation.

> On Team and Enterprise plans, organization owners can provision the skill for everyone.

> As with any third-party skill, read it before installing. It is just two Markdown files, no executable code: [`SKILL.md`](../../skills/google-ads-analyst/SKILL.md) and [`references/gaql-recipes.md`](../../skills/google-ads-analyst/references/gaql-recipes.md).

## Example prompts

```
Which accounts are under my MCC and which are active?
How did account X perform over the last 30 days? Full report, please.
Compare October with September on account X.
Which search terms spent without converting? Suggest negatives.
Which campaigns are losing impression share to budget?
Who changed account X in the last two weeks, and what changed?
```

## Customize

Fork the repo and edit `SKILL.md`, for example to add your clients' CPA targets or your report template. Then package it:

```bash
scripts/package-skill.sh   # creates dist/google-ads-analyst.zip
```

Validate before packaging:

```bash
python3 tests/validate-skill.py
```
