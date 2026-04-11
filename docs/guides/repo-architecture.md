# Two-Repo Architecture: Agent Behavior vs World Knowledge

Your AI agent setup should use two separate repositories with strict separation.

## The Boundary Test

**"Is this about how the agent operates, or is this knowledge about the world?"**

| Question | If YES → Agent Repo | If YES → Brain Repo |
|----------|---------------------|---------------------|
| Would this file transfer if you switched AI agents? | YES | — |
| Would this file transfer if you switched to a different person? | — | YES |
| Is this about how the agent behaves? | YES | — |
| Is this about a person, company, deal, meeting, or idea? | — | YES |

## Agent Repo (operational config)

How the agent works. Identity, configuration, operational state.

```
agent-repo/
├── AGENTS.md              # Agent identity + operational rules
├── SOUL.md                # Persona, voice, values
├── USER.md                # User preferences + context
├── HEARTBEAT.md           # Daily ops flow
├── TOOLS.md               # Available tools + credentials
├── MEMORY.md              # Operational memory (preferences, decisions)
├── skills/                # Agent capabilities (SKILL.md files)
│   ├── ingest/SKILL.md
│   ├── query/SKILL.md
│   ├── enrich/SKILL.md
│   └── ...
├── cron/                  # Scheduled jobs
│   └── jobs.json
├── tasks/                 # Current task list
│   └── current.md
├── hooks/                 # Event hooks + transforms
├── scripts/               # Operational scripts (collectors, gates)
└── memory/                # Session logs, state files
    ├── heartbeat-state.json
    └── YYYY-MM-DD.md      # Daily session logs
```

## Brain Repo (world knowledge)

What you know. People, companies, deals, meetings, ideas, media.
This is the repo GBrain indexes.

```
brain/
├── people/                # Person dossiers (compiled truth + timeline)
├── companies/             # Company profiles
├── deals/                 # Deal tracking
├── meetings/              # Meeting transcripts + analysis
├── originals/             # YOUR original thinking (highest value)
├── concepts/              # World concepts and frameworks
├── ideas/                 # Product and business ideas
├── media/                 # Video transcripts, books, articles
│   ├── youtube/
│   ├── podcasts/
│   └── articles/
├── sources/               # Source material summaries
├── daily/                 # Daily data (calendar, logs)
│   └── calendar/
│       └── YYYY/
│           └── YYYY-MM-DD.md
├── projects/              # Project specs and docs
├── writing/               # Essays, drafts, published work
├── diligence/             # Investment diligence materials
│   └── company-name/
│       ├── index.md
│       ├── pitch-deck.md
│       └── .raw/          # Original PDFs/files
└── Apple Notes/           # Imported Apple Notes archive
```

## The Hard Rule

**Never write knowledge to the agent repo.** If a skill, sub-agent, or cron
job needs to create a file about a person, company, deal, meeting, project,
or idea, it MUST write to the brain repo, never to the agent repo.

The brain is the permanent record. The agent repo is replaceable.

## Quick Decision Tree

```
New file to create?
  ├── About a person, company, deal, project, meeting, idea? → brain/
  ├── A spec, research doc, or strategic analysis? → brain/
  ├── An original idea or observation? → brain/originals/
  ├── A daily session log or heartbeat state? → agent-repo/
  ├── A skill, config, cron, or ops file? → agent-repo/
  └── A task or todo? → agent-repo/tasks/
```

## Why Two Repos

**Independence.** You can switch AI agents (OpenClaw → Hermes → custom) without
losing your knowledge. You can switch knowledge tools (GBrain → something else)
without losing your agent setup.

**Scale.** The brain grows large (10,000+ files). The agent repo stays small
(< 100 files). Different backup strategies, different sync cadences.

**Privacy.** The brain contains sensitive information (people, deals, personal
notes). The agent repo contains operational config. Different access controls.

**GBrain indexes the brain repo.** Run `gbrain sync --repo ~/brain/` to keep
the search index current. The agent repo is never indexed by GBrain.

---

*Part of the [GBrain Skillpack](../GBRAIN_SKILLPACK.md). See also: [Brain vs Agent Memory](brain-vs-memory.md)*
