---
id: calendar-to-brain
name: Calendar-to-Brain
version: 0.7.0
description: Google Calendar events become searchable brain pages. Daily files with attendees, locations, and meeting prep context.
category: sense
requires: []
secrets:
  - name: CLAWVISOR_URL
    description: ClawVisor gateway URL (or any credential gateway with Google Calendar access)
    where: https://clawvisor.com — create an agent, activate Google Calendar service
  - name: CLAWVISOR_AGENT_TOKEN
    description: ClawVisor agent token for authenticated requests
    where: https://clawvisor.com — agent settings, copy the agent token
health_checks:
  - "curl -sf $CLAWVISOR_URL/health > /dev/null && echo 'ClawVisor: OK' || echo 'ClawVisor: FAIL'"
setup_time: 20 min
cost_estimate: "$0 (ClawVisor free tier covers calendar access)"
---

# Calendar-to-Brain: Your Schedule Becomes Searchable Memory

Every calendar event becomes a searchable brain page. Your agent knows who you're
meeting tomorrow, what you discussed last time, and what context matters. Meeting
prep happens automatically because the brain already has the history.

## IMPORTANT: Instructions for the Agent

**You are the installer.** Follow these steps precisely.

**Why this matters:** Calendar data is the richest source of relationship history.
13 years of calendar data tells you who you've met with, how often, where, and
with whom. When someone emails you, the brain already knows your meeting history.
When you have a meeting tomorrow, the agent pulls attendee dossiers automatically.

**The output is daily markdown files:** One file per day at
`brain/daily/calendar/{YYYY}/{YYYY-MM-DD}.md` with all events, attendees, and
locations. These files are the foundation for meeting prep, relationship tracking,
and pattern detection.

**Do not skip steps. Verify after each step.**

## Architecture

```
Google Calendar (multiple accounts)
  ↓ (ClawVisor credential gateway, paginated)
Calendar Sync Script (deterministic Node.js)
  ↓ Outputs:
  ├── brain/daily/calendar/{YYYY}/{YYYY-MM-DD}.md   (daily event files)
  ├── brain/daily/calendar/.raw/events-{range}.json  (raw API responses)
  └── brain/daily/calendar/INDEX.md                  (date ranges + monthly summary)
  ↓
Agent reads daily files
  ↓ Judgment calls:
  ├── Attendee enrichment (create/update brain pages for people)
  ├── Meeting prep (pull context before tomorrow's meetings)
  └── Pattern detection (meeting frequency, relationship temperature)
```

## Opinionated Defaults

**Multiple calendar accounts:**
- Work calendar (company domain)
- Personal calendar (gmail.com)
- Previous company calendars (if still accessible)

**Daily file format:**
```markdown
# 2026-04-10 (Thursday)

- 09:00-09:30 **Team standup** (Work) — with Alice, Bob, Carol
- 10:00-11:00 **Board meeting** (Work) 📍 Office — with Diana, Eduardo, Fiona
- 12:00-13:00 **Lunch with Pedro** (Personal) 📍 Chez Panisse — with Pedro Franceschi
- 14:00-14:30 **1:1 with Jordan** (Work) — with Jordan Lee
```

All-day events listed first. Timed events sorted by start time.
Cancelled events are skipped. Attendee names extracted (no email addresses in output).
Calendar label in parentheses. Location with 📍 emoji.

**Historical backfill:** Sync years of calendar data, not just recent. Common ranges:
- Work: 2020-present
- Personal: 2014-present
This builds the full relationship graph from day one.

## Prerequisites

1. **GBrain installed and configured** (`gbrain doctor` passes)
2. **Node.js 18+** (for the sync script)
3. **Google Calendar access** via credential gateway (ClawVisor or Hermes)

## Setup Flow

### Step 1: Validate Credential Gateway

Tell the user:
"I need access to your Google Calendar. Here's how to set it up:

1. Go to https://clawvisor.com (or your credential gateway)
2. Create an agent (or use existing)
3. Activate the **Google Calendar** service
4. Create a standing task with purpose: 'Full calendar access for historical
   backfill and ongoing sync. List events, read event details, search across
   all calendars.'
   IMPORTANT: Be EXPANSIVE in the task purpose. Narrow purposes block requests.
5. Copy the gateway URL and agent token"

Validate:
```bash
curl -sf "$CLAWVISOR_URL/health" && echo "PASS: ClawVisor reachable" || echo "FAIL"
```

**STOP until credential gateway validates.**

### Step 2: Identify Calendar Accounts

Ask the user: "Which Google Calendar accounts should I sync? Common setup:
- Work email (e.g., you@company.com)
- Personal email (e.g., you@gmail.com)
- Any previous company emails with calendar history"

For each account, note:
- Email address
- Start year (how far back to sync)
- Label (Work, Personal, etc.)

### Step 3: Set Up the Calendar Sync Script

Create the sync directory:
```bash
mkdir -p calendar-sync
cd calendar-sync
npm init -y
```

The sync script needs these capabilities:

1. **Paginated event retrieval** — Google Calendar API returns max 50 events per
   request. The script must paginate through large date ranges. Use monthly chunks
   for sparse periods, weekly for dense ones.
2. **Daily markdown generation** — group events by date, format as markdown with
   times, attendees, locations, calendar labels
3. **Merge with existing files** — if a daily file already has manual notes, preserve
   them when updating calendar data
4. **Index generation** — create INDEX.md with date ranges, event counts, monthly summary
5. **Raw JSON preservation** — save raw API responses to `.raw/` for provenance

### Step 4: Run Historical Backfill

This is the big initial sync. It may take 10-30 minutes depending on how many
years of calendar data you have.

```bash
node calendar-sync.mjs --start 2020-01-01 --end $(date +%Y-%m-%d)
```

Tell the user: "Syncing calendar history from [start year]. This creates one
markdown file per day. For 4 years of data, expect ~1,400 daily files."

Verify:
```bash
ls brain/daily/calendar/2026/ | head -10
```

Should show daily files like `2026-04-01.md`, `2026-04-02.md`, etc.

### Step 5: Import Calendar Data to GBrain

```bash
gbrain import brain/daily/calendar/ --no-embed
gbrain embed --stale
```

Verify:
```bash
gbrain search "meeting" --limit 3
```

Should return calendar pages with event details.

### Step 6: Attendee Enrichment

This is YOUR job (the agent). For each person who appears in calendar events:

1. **Check brain**: `gbrain search "attendee name"` — do they have a page?
2. **Create page if missing**: notable attendees (appears 3+ times) get a brain page
3. **Update existing pages**: add meeting history to timeline:
   `- YYYY-MM-DD | Meeting: {event title} [Source: Google Calendar]`
4. **Relationship tracking**: note meeting frequency in compiled truth:
   "Met 12 times in last 6 months. Regular 1:1 cadence."

### Step 7: Set Up Weekly Sync

The calendar should sync weekly to stay current:
```bash
# Cron: every Sunday at 10 AM
0 10 * * 0 cd /path/to/calendar-sync && node calendar-sync.mjs --start $(date -v-7d +%Y-%m-%d) --end $(date +%Y-%m-%d)
```

After sync, import new data:
```bash
gbrain sync --no-pull --no-embed && gbrain embed --stale
```

### Step 8: Log Setup Completion

```bash
mkdir -p ~/.gbrain/integrations/calendar-to-brain
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","event":"setup_complete","source_version":"0.7.0","status":"ok","details":{"accounts":"ACCOUNT_COUNT","start_year":"YYYY"}}' >> ~/.gbrain/integrations/calendar-to-brain/heartbeat.jsonl
```

Tell the user: "Calendar-to-brain is set up. You have [N] days of calendar history
indexed. I can now prep you for meetings by pulling attendee context from the brain.
Weekly sync keeps it current."

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| ClawVisor (free tier) | $0 |
| Google Calendar API | $0 (within free quota) |
| **Total** | **$0** |

## Troubleshooting

**No events returned:**
- Check the calendar account email is correct
- Check ClawVisor has Google Calendar service activated
- Check the standing task purpose is expansive enough
- Some calendars may be empty for the requested date range

**Attendee names missing:**
- Google Calendar sometimes returns email addresses instead of display names
- The sync script should extract the display name from the attendee object
- If no display name, use the email prefix (before @)

**Duplicate events:**
- The sync script should be idempotent (same date range = same output)
- If running multiple times, existing daily files are overwritten (not appended)
