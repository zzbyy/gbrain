---
id: x-to-brain
name: X-to-Brain
version: 0.7.0
description: Twitter timeline, mentions, and keyword monitoring flow into brain pages. Tracks deletions and engagement velocity.
category: sense
requires: []
secrets:
  - name: X_BEARER_TOKEN
    description: X API v2 Bearer token (Basic tier minimum, $200/mo for full archive search)
    where: https://developer.x.com/en/portal/dashboard — create a project + app, copy the Bearer Token from "Keys and tokens"
health_checks:
  - "curl -sf -H \"Authorization: Bearer $X_BEARER_TOKEN\" \"https://api.x.com/2/users/me\" > /dev/null && echo 'X API: OK' || echo 'X API: FAIL'"
setup_time: 15 min
cost_estimate: "$0-200/mo (Free tier: 1 app, read-only. Basic: $200/mo for search + higher limits)"
---

# X-to-Brain: Twitter Monitoring That Updates Your Brain

Your timeline, mentions, and keyword searches flow into brain pages. The collector
tracks deletions, engagement velocity, and narrative patterns. You wake up knowing
what happened on X while you slept.

## IMPORTANT: Instructions for the Agent

**You are the installer.** Follow these steps precisely.

**The core pattern: code for data, LLMs for judgment.**
The X collector is deterministic code. It pulls tweets, detects deletions, tracks
engagement. It NEVER interprets content. YOU (the agent) read the collected data
and make judgment calls: who is important, what entities are mentioned, what
narratives are forming.

**Why sequential execution matters:**
- Step 1 validates the API key. Without it, nothing connects to X.
- Step 2 sets up the collector. Without it, you have no data.
- Step 3 runs the first collection. Without data, you can't enrich.
- Step 4 is YOUR job: read the collected tweets, update brain pages.

**Do not skip steps. Do not reorder. Verify after each step.**

## Architecture

```
X API v2 (Bearer token auth)
  ↓ Three collection streams:
  ├── Own timeline: GET /users/{id}/tweets
  ├── Mentions: GET /users/{id}/mentions
  └── Keyword searches: GET /tweets/search/recent
  ↓
X Collector (deterministic Node.js script)
  ↓ Outputs:
  ├── data/tweets/{own,mentions,searches}/{id}.json
  ├── data/deletions/{id}.json (detected via diff)
  ├── data/engagement/{id}.json (velocity snapshots)
  └── data/state.json (pagination, rate limits)
  ↓
Agent reads collected data
  ↓ Judgment calls:
  ├── Entity detection (people, companies mentioned)
  ├── Brain page updates (timeline entries)
  ├── Narrative pattern detection
  └── Engagement spike alerts
```

## Opinionated Defaults

**Three collection streams:**
1. **Own timeline** — your tweets, for your own archive and engagement tracking
2. **Mentions** — who is talking about you, for relationship tracking
3. **Keyword searches** — topics you care about, for signal detection

**Deletion detection:**
- Compare tweet IDs from previous run vs current
- If an ID is missing AND the tweet is < 7 days old, call GET /tweets/{id}
- 404 = confirmed deleted. Save the original tweet + deletion timestamp.
- Alert on deletions from accounts you track.

**Engagement velocity:**
- Snapshot likes/retweets/replies for tracked tweets
- Alert if likes doubled AND previous count >= 50
- Alert if likes gained > 100 absolute since last check
- Only write snapshot if metrics actually changed (idempotent)

**Rate limit awareness:**
- Basic tier: 1500 req/15min for timeline, 450 for mentions, 60 for search
- Collector tracks rate limits in state.json
- Back off automatically when approaching limits

## Prerequisites

1. **GBrain installed and configured** (`gbrain doctor` passes)
2. **Node.js 18+** (for the collector script)
3. **X Developer account** with API access

## Setup Flow

### Step 1: Get X API Credentials

Tell the user:
"I need your X API Bearer token. Here's exactly where to get it:

1. Go to https://developer.x.com/en/portal/dashboard
2. If you don't have a developer account, click 'Sign up' (free tier available)
3. Create a new Project (name it anything, e.g., 'GBrain')
4. Inside the project, create a new App
5. Go to the app's 'Keys and tokens' tab
6. Under 'Bearer Token', click 'Generate' (or 'Regenerate')
7. Copy the Bearer Token and paste it to me

Note: Free tier gives read-only access with low limits. Basic tier ($200/mo)
gives search/recent endpoint and higher limits. Pro tier gets full archive search."

Validate immediately:
```bash
curl -sf -H "Authorization: Bearer $X_BEARER_TOKEN" \
  "https://api.x.com/2/users/me" \
  && echo "PASS: X API connected" \
  || echo "FAIL: X API token invalid"
```

**If validation fails:** "That didn't work. Common issues: (1) make sure you copied
the Bearer Token, not the API Key or API Secret, (2) Bearer Tokens are long strings
starting with 'AAA...', (3) if you just created the app, the token is valid immediately."

**STOP until X API validates.**

### Step 2: Get Your X User ID

```bash
# Look up the user's X user ID from their handle
curl -sf -H "Authorization: Bearer $X_BEARER_TOKEN" \
  "https://api.x.com/2/users/by/username/USERNAME" | grep -o '"id":"[^"]*"'
```

Ask the user for their X handle (e.g., @garrytan). Look up their user ID.
Save it — the collector needs the numeric ID, not the handle.

### Step 3: Configure the Collector

Create the collector directory:
```bash
mkdir -p x-collector/data/{tweets/{own,mentions,searches},deletions,engagement}
cd x-collector
```

The collector script needs these capabilities:

1. **collect** — pull tweets from three streams:
   - Own timeline: `GET /2/users/{id}/tweets` with max_results=100
   - Mentions: `GET /2/users/{id}/mentions` with max_results=100
   - Keyword searches: configurable search terms via `GET /2/tweets/search/recent`
2. **Deletion detection** — compare previous run's tweet IDs vs current. For missing IDs, verify with individual tweet lookup. 404 = deleted.
3. **Engagement tracking** — snapshot metrics for tracked tweets. Only write if metrics changed.
4. **State management** — save pagination tokens, last run timestamp, rate limit state to `data/state.json`
5. **Atomic writes** — write to .tmp file, then rename (prevents corrupt data on crash)

Configure keyword searches based on what the user cares about:
```json
{
  "searches": [
    "\"your name\" -from:yourhandle",
    "\"your company\" OR \"your product\"",
    "topic you track"
  ]
}
```

### Step 4: Run First Collection

```bash
node x-collector.mjs collect
```

Verify: `ls data/tweets/own/` should contain tweet JSON files.
Show the user a sample: "Found N tweets from your timeline, M mentions, K search results."

### Step 5: Enrich Brain Pages

This is YOUR job (the agent). Read the collected tweets:

1. **Detect entities**: who tweeted? Who is mentioned? What companies/topics?
2. **Check the brain**: `gbrain search "person name"` — do we have a page?
3. **Update brain pages**: for each notable person or company mentioned:
   `- YYYY-MM-DD | Tweeted about {topic} [Source: X, @handle, {date}]`
4. **Track narratives**: if someone tweets about the same topic 3+ times in a week, note the pattern in their compiled truth
5. **Flag deletions**: if a tracked account deleted a tweet, note it:
   `- YYYY-MM-DD | Deleted tweet: "{content}" [Source: X deletion, detected {date}]`
6. **Sync**: `gbrain sync --no-pull --no-embed`

### Step 6: Set Up Cron

The collector should run every 30 minutes:
```bash
*/30 * * * * cd /path/to/x-collector && node x-collector.mjs collect >> /tmp/x-collector.log 2>&1
```

The agent should review collected data 2-3x daily and run enrichment.

### Step 7: Log Setup Completion

```bash
mkdir -p ~/.gbrain/integrations/x-to-brain
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","event":"setup_complete","source_version":"0.7.0","status":"ok","details":{"user_id":"X_USER_ID"}}' >> ~/.gbrain/integrations/x-to-brain/heartbeat.jsonl
```

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| X API Free tier | $0 (read-only, low limits) |
| X API Basic tier | $200/mo (search + higher limits) |
| X API Pro tier | $5,000/mo (full archive) |
| **Recommended** | **$0 (free) or $200 (basic)** |

Free tier works for personal monitoring. Basic tier needed for keyword search.

## Troubleshooting

**API returns 403:**
- Check your app has the right access level (Read or Read+Write)
- Free tier apps can only use basic endpoints
- Some endpoints require Basic or Pro tier

**Rate limited (429):**
- The collector respects rate limits automatically
- If hitting limits frequently, increase the cron interval to 60 minutes
- Check `data/state.json` for rate limit tracking

**No tweets collected:**
- Verify the user ID is correct (numeric, not handle)
- Check the Bearer Token is valid (Step 1 validation)
- Some accounts may have protected tweets (requires OAuth 2.0 user context)
