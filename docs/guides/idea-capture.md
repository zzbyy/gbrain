# Idea Capture: Originals, Depth, and Distribution

The originals folder is the highest-value content in the brain. It captures
WHAT YOU THINK, not just what you found.

## The Authorship Test

| Signal | Destination |
|--------|-------------|
| User generated the idea | `brain/originals/{slug}.md` |
| User's unique synthesis of others' ideas | `brain/originals/` (the synthesis is original) |
| World concept someone else coined | `brain/concepts/{slug}.md` |
| Product or business idea | `brain/ideas/{slug}.md` |
| User's ghostwritten book/essay | `brain/originals/` (note ghostwriter in metadata) |
| Article ABOUT user | `brain/media/writings/` |

## Capture Standards

**Use the user's EXACT phrasing.** The language IS the insight.

"The ambition-to-lifespan ratio has never been more broken" captures something that
"tension between ambition and mortality" doesn't. Don't clean it up. Don't paraphrase.
The vivid version is the real version.

**What counts as worth capturing:**
- Original observations about how the world works
- Novel connections between disparate things
- Frameworks and mental models
- Pattern recognition moments ("I keep seeing X in every Y")
- Hot takes with reasoning behind them
- Metaphors that reveal new angles
- Emotional/psychological insights about self or others

**What does NOT count:**
- Routine operational messages ("ok", "do it")
- Pure questions without embedded observations
- Echoing back something the agent said
- Acknowledgments and reactions

## The Depth Test

**Could someone unfamiliar with the user read this page and understand not
just WHAT they think but WHY and HOW they got there?**

If the answer is no, it needs more depth. Include:
- The reasoning path (what led to the insight)
- The influences (what they were reading/watching/experiencing)
- The context (conversation, meeting, moment)
- The emotional or psychological nuance

## Originality Distribution Rating

For notable ideas, rate originality 0-100 across different populations:

```markdown
## Originality Distribution

- **General population:** 72/100 — most people haven't encountered this framework
- **Tech industry:** 45/100 — common in startup circles but novel to most
- **Intellectual/media class:** 68/100 — would resonate, not yet articulated
- **Political establishment:** 82/100 — completely foreign to policy thinking

**Publish signal:** Strong essay candidate. Best audience: founders, builders.
```

This tells the user which ideas are worth turning into essays, talks, or videos,
and which audience would find them most novel.

## Deep Cross-Linking Mandate

**An original without cross-links is a dead original.** The connections ARE
the intelligence.

Every original MUST link to:
- **People** who shaped the thinking → `people/{name}.md`
- **Companies** where the idea played out → `companies/{name}.md`
- **Meetings** where it was discussed → `meetings/{date}-{slug}.md`
- **Books and media** that influenced it → `media/{type}/{name}.md`
- **Other originals** it connects to (ideas form clusters)
- **Concepts** it builds on or challenges → `concepts/{name}.md`

Over time, the originals folder becomes a searchable archive of the user's
intellectual output, organized by topic clusters and cross-referenced to
everything that influenced it. This is the memex at its most powerful.

## Notability Filtering

Before creating any entity page, check notability:

**Create a page for:**
- People you know or discuss with specificity
- Companies you're evaluating, working with, or investing in
- Media you mention with personal reaction
- Anyone you've explicitly engaged with

**Don't create pages for:**
- Generic references or passing examples
- Low-engagement accounts who mentioned you once
- Pure metaphors ("like the Roman Empire...")
- One-off encounters with no follow-up

**Decision:** If notable AND no page exists → create a full page with web
search enrichment. No stubs. If you make a page, make it good.

---

*Part of the [GBrain Skillpack](../GBRAIN_SKILLPACK.md). See also: [Entity Detection](entity-detection.md), [The Originals Folder](originals-folder.md)*
