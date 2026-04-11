# Quiet Hours and Timezone-Aware Delivery

Your brain never sleeps, but your notifications should.

## Quiet Hours Gate

Every cron job that sends notifications must check quiet hours FIRST.

```
QUIET_START = 23  // 11 PM local time
QUIET_END = 8     // 8 AM local time

is_quiet(local_hour):
  return local_hour >= QUIET_START OR local_hour < QUIET_END
```

**Before sending any notification:**
1. Determine user's current timezone (from config or heartbeat state)
2. Convert current UTC time to local time
3. If quiet hours: hold the message, don't send

## Held Messages

During quiet hours, output goes to a held directory instead of being sent:

```
if is_quiet():
  mkdir -p /tmp/cron-held/
  write("/tmp/cron-held/{job-name}.md", output)
  exit  // don't send
else:
  send(output)
```

The morning briefing picks up held messages:

```
morning_briefing():
  held_files = list("/tmp/cron-held/*.md")
  if held_files:
    briefing += "## Overnight Updates\n\n"
    for file in held_files:
      briefing += read(file)
      delete(file)
```

This way nothing is lost. Overnight cron results get folded into the
first thing the user sees in the morning.

## Timezone Awareness

The agent should know what timezone the user is in. Store it in
the agent's operational state:

```json
{
  "currentLocation": {
    "timezone": "US/Pacific",
    "city": "San Francisco"
  }
}
```

**Update the timezone when:**
- Calendar shows the user flying somewhere (check for airline/hotel events)
- User mentions being in a different city
- User's active hours shift (they're responding at 3 AM PT = they're probably traveling)

**All times shown to the user should be in their LOCAL timezone.** Never
show UTC or a timezone the user isn't in.

## Implementation Pattern

```bash
#!/bin/bash
# quiet-hours-gate.sh — run before any notification

TIMEZONE="${USER_TIMEZONE:-US/Pacific}"
LOCAL_HOUR=$(TZ="$TIMEZONE" date +%H)

if [ "$LOCAL_HOUR" -ge 23 ] || [ "$LOCAL_HOUR" -lt 8 ]; then
  echo "QUIET_HOURS=true"
  exit 1  # don't send
fi

echo "QUIET_HOURS=false"
exit 0  # ok to send
```

**In cron job scripts:**
```bash
# Check quiet hours first
if ! bash scripts/quiet-hours-gate.sh; then
  mkdir -p /tmp/cron-held
  echo "$OUTPUT" > /tmp/cron-held/$(basename "$0" .sh).md
  exit 0
fi

# Not quiet hours — send normally
send_notification "$OUTPUT"
```

## Configurable Hours

Some users want different quiet hours. Store the config:

```json
{
  "quiet_hours": {
    "start": 23,
    "end": 8,
    "enabled": true
  }
}
```

Set `enabled: false` to disable quiet hours entirely (e.g., for 24/7 monitoring).

---

*Part of the [GBrain Skillpack](../GBRAIN_SKILLPACK.md). See also: [Cron Schedule](cron-schedule.md), [Operational Disciplines](operational-disciplines.md)*
