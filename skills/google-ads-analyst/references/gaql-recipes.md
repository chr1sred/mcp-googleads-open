# Validated GAQL recipes

Each recipe is a `search` tool call, validated against a live account. Replace:

- `<CID>`: account ID, digits only
- `<MCC>`: manager ID, passed as `login_customer_id` (omit if the account is accessed directly)
- `<START>` / `<END>`: `YYYY-MM-DD`

Field names must be used exactly as written: full names, no wildcards.

---

## R1 · Account info / is it an MCC?

```json
{
  "customer_id": "<CID>",
  "resource": "customer",
  "fields": ["customer.id", "customer.descriptive_name", "customer.manager",
             "customer.currency_code", "customer.status"]
}
```

## R2 · Every account under an MCC (1 operation)

```json
{
  "customer_id": "<MCC>",
  "login_customer_id": "<MCC>",
  "resource": "customer_client",
  "fields": ["customer_client.id", "customer_client.descriptive_name",
             "customer_client.manager", "customer_client.level",
             "customer_client.status", "customer_client.currency_code"],
  "conditions": ["customer_client.level <= 1"]
}
```

`level 0` is the MCC itself. Child MCCs have `manager = true`; repeat R2 on them for deeper trees.

## R3 · Campaign performance

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "campaign",
  "fields": ["campaign.id", "campaign.name", "campaign.status",
             "campaign.advertising_channel_type", "campaign.bidding_strategy_type",
             "metrics.impressions", "metrics.clicks", "metrics.ctr",
             "metrics.average_cpc", "metrics.cost_micros", "metrics.conversions",
             "metrics.conversions_value", "metrics.cost_per_conversion"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'",
                 "campaign.status != 'REMOVED'", "metrics.impressions > 0"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 50
}
```

Without `metrics.impressions > 0`, paused campaigns with no delivery come back as zero rows.

## R4 · Daily trend (whole account)

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "customer",
  "fields": ["segments.date", "metrics.impressions", "metrics.clicks",
             "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'"],
  "orderings": ["segments.date"]
}
```

For period comparison, run it (or R3) for both ranges and sum.

## R5 · Budget and lost impression share

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "campaign",
  "fields": ["campaign.name", "campaign_budget.amount_micros", "campaign_budget.period",
             "metrics.cost_micros", "metrics.search_impression_share",
             "metrics.search_budget_lost_impression_share",
             "metrics.search_rank_lost_impression_share"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'",
                 "campaign.status = 'ENABLED'", "metrics.impressions > 0"],
  "orderings": ["metrics.cost_micros DESC"]
}
```

Impression share is Search-only: show N/A for other channel types. Budget-lost > 20% is a watch-out.

## R6 · Ad group performance

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "ad_group",
  "fields": ["campaign.name", "ad_group.name", "ad_group.status",
             "metrics.impressions", "metrics.clicks", "metrics.cost_micros",
             "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'", "metrics.impressions > 0"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 20
}
```

## R7 · Keywords and Quality Score

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "keyword_view",
  "fields": ["ad_group_criterion.keyword.text", "ad_group_criterion.keyword.match_type",
             "ad_group_criterion.quality_info.quality_score", "campaign.name",
             "ad_group.name", "metrics.impressions", "metrics.clicks",
             "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'",
                 "ad_group_criterion.status = 'ENABLED'", "metrics.impressions > 0"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 20
}
```

`quality_score = 0` means **no score yet**, not a score of zero.

## R8 · Search terms

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "search_term_view",
  "fields": ["search_term_view.search_term", "search_term_view.status", "campaign.name",
             "metrics.impressions", "metrics.clicks", "metrics.cost_micros",
             "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 25
}
```

`status`: `ADDED` = already a keyword, `EXCLUDED` = already negative, `NONE` = candidate. Terms with spend and 0 conversions are negative-keyword candidates. Converting `NONE` terms are keyword opportunities.

## R9 · Conversions by action

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "customer",
  "fields": ["segments.conversion_action_name", "segments.conversion_action_category",
             "metrics.all_conversions", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'"],
  "orderings": ["metrics.all_conversions DESC"]
}
```

`conversions` counts only actions marked as primary (used for bidding). `all_conversions` includes secondary ones. A big gap between them is worth explaining to the user.

## R10 · Device split

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "customer",
  "fields": ["segments.device", "metrics.impressions", "metrics.clicks",
             "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'"],
  "orderings": ["metrics.cost_micros DESC"]
}
```

Use `customer` (not `campaign`) for one row per device; `campaign` repeats devices per campaign.

## R11 · Locations with names (2 calls)

Step 1, performance by region:

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "geographic_view",
  "fields": ["geographic_view.country_criterion_id", "geographic_view.location_type",
             "segments.geo_target_region", "metrics.impressions", "metrics.clicks",
             "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'",
                 "geographic_view.location_type = 'LOCATION_OF_PRESENCE'"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 10
}
```

Step 2: `segments.geo_target_region` returns `geoTargetConstants/<ID>`. Resolve all IDs in **one** call:

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "geo_target_constant",
  "fields": ["geo_target_constant.id", "geo_target_constant.name",
             "geo_target_constant.canonical_name", "geo_target_constant.target_type"],
  "conditions": ["geo_target_constant.id IN (<ID1>, <ID2>, <ID3>)"]
}
```

## R12 · Responsive search ads and Ad Strength

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "ad_group_ad",
  "fields": ["campaign.name", "ad_group.name", "ad_group_ad.ad.id",
             "ad_group_ad.ad_strength", "ad_group_ad.policy_summary.approval_status",
             "metrics.impressions", "metrics.clicks", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '<START>' AND '<END>'",
                 "ad_group_ad.status = 'ENABLED'",
                 "ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD'"],
  "orderings": ["metrics.impressions DESC"],
  "limit": 20
}
```

Ad Strength only exists for RSAs. Other ad types return `UNSPECIFIED`. Flag `POOR`/`AVERAGE` strength and any approval status other than `APPROVED`.

## R13 · Recent changes (who changed what)

```json
{
  "customer_id": "<CID>",
  "login_customer_id": "<MCC>",
  "resource": "change_event",
  "fields": ["change_event.change_date_time", "change_event.change_resource_type",
             "change_event.resource_change_operation", "change_event.user_email",
             "change_event.client_type", "change_event.changed_fields", "campaign.name"],
  "conditions": ["change_event.change_date_time >= '<START>'",
                 "change_event.change_date_time <= '<END>'"],
  "orderings": ["change_event.change_date_time DESC"],
  "limit": 50
}
```

Limits: only the **last 30 days**, and `limit` is mandatory (≤ 10,000). Use it to explain sudden performance shifts ("CPA target lowered on day X"). It contains user e-mails, so mention people only when the user asks who made a change.
