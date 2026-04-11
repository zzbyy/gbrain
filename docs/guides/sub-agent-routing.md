# Sub-Agent Model Routing

Not every task needs your most expensive model. Route sub-agents to the right
model for the job.

## Routing Table

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Main session / complex instructions | Opus-class (default) | Best reasoning and instruction following |
| Research / synthesis / analysis | DeepSeek V3 or equivalent | 25-40x cheaper, strong on exploratory work |
| Structured output / long context | Large context model (Qwen, Gemini) | 200K+ context, reliable JSON output |
| Fast lightweight sub-agents | Fast inference model (Groq) | 500 tok/s, cheap, good for quick tasks |
| Deep reasoning (use sparingly) | Reasoning model (DeepSeek-R1, o3) | Best for hard problems, expensive |
| Entity detection (signal detector) | Sonnet-class | Fast, cheap, sufficient quality for detection |

## The Signal Detector Pattern

Spawn a lightweight sub-agent on EVERY inbound message. This is mandatory.

```
on_every_message(text):
  // Spawn async — don't block the response
  spawn_subagent({
    task: `SIGNAL DETECTION — scan this message:
    "${text}"

    1. IDEAS FIRST: Is the user expressing an original thought?
       If yes → create/update brain/originals/ with EXACT phrasing
    2. ENTITIES: Extract person names, company names, media titles
       For each → check brain, create/enrich if notable
    3. FACTS: New info about existing entities → update timeline
    4. CITATIONS: Every fact needs [Source: ...] attribution
    5. Sync changes to brain repo`,
    model: "sonnet-class",  // fast + cheap
    timeout: 120s
  })
```

**Why Sonnet-class for detection:** Entity detection is pattern matching, not
deep reasoning. Sonnet is 5-10x cheaper than Opus and fast enough for async
detection. The main session continues on Opus while detection runs in parallel.

## Research Pipeline Pattern

For research-heavy tasks, use a multi-model pipeline:

```
1. PLANNING (Opus):     Write research brief, identify what to look for
2. EXECUTION (DeepSeek): Sub-agent does the actual research (web, APIs, docs)
3. SYNTHESIS (Opus):     Read research output, add strategic analysis
```

**Why this works:** The planning and synthesis steps need taste and judgment
(Opus). The execution step is mechanical data gathering (DeepSeek at 25-40x
lower cost). You get Opus-quality output at DeepSeek-level cost for 80% of
the work.

## When to Spawn Sub-Agents

| Situation | Spawn? | Model |
|-----------|--------|-------|
| Every inbound message | YES (mandatory) | Sonnet |
| Research request | YES | DeepSeek for execution |
| Quick lookup / fact check | YES | Fast model (Groq) |
| Complex analysis | NO — handle in main session | Opus |
| Writing / editing | NO — handle in main session | Opus |

## Cost Optimization

The main session runs on your best model. Everything else runs on the
cheapest model that can do the job. In practice, 60-70% of sub-agent
work is entity detection (Sonnet) and research execution (DeepSeek),
which are 10-40x cheaper than the main session model.

---

*Part of the [GBrain Skillpack](../GBRAIN_SKILLPACK.md). See also: [Entity Detection](entity-detection.md), [Enrichment Pipeline](enrichment-pipeline.md)*
