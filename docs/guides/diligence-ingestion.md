# Diligence Ingestion: Data Room to Brain Pages

When you receive pitch decks, financial models, cap tables, or investor memos,
this pipeline turns them into searchable, cross-referenced brain pages.

## Detection

Recognize data room materials by:

**PDF filenames containing:**
- "Data Deck", "Intro Deck", "Data Room", "Cap Table"
- "Financial Model", "Investor Memo", "Pitch Deck"
- "Series A", "Series B", "Series C", "Series D"

**Spreadsheet tabs:**
- Revenue, Retention, Cohorts, CAC, Gross Margin
- Unit Economics, ARR

**User language:**
- "data room", "diligence", "deck", "pitch", "fundraise materials"

## The 9-Step Pipeline

### Step 1: Identify the Company

From the document content or filename, identify the company name.
Check if `brain/companies/{slug}.md` exists.

### Step 2: Create Diligence Directory

```bash
mkdir -p brain/diligence/{company-slug}/.raw
```

### Step 3: Extract Content

- **PDFs:** Use PDF extraction tool. For scanned/image-heavy PDFs,
  use OCR (e.g., Mistral OCR or similar).
- **Spreadsheets:** Export each sheet as CSV. For Google Sheets:
  ```
  https://docs.google.com/spreadsheets/d/{ID}/gviz/tq?tqx=out:csv&sheet={Sheet Name}
  ```

### Step 4: Diarize and Save

Write extracted content to `brain/diligence/{company}/{doc-name}.md`:
- Document title and type
- Section-by-section breakdown with key metrics
- Notable footnotes or caveats
- Raw data tables where relevant

### Step 5: Save Raw Files

Copy original PDFs/files to `brain/diligence/{company}/.raw/`
Preserve originals for reference. The diarized version is for search.

### Step 6: Create or Update index.md

Every diligence directory needs an `index.md`:

```markdown
# {Company Name} — Diligence

## Round Details
- Stage: Series A
- Amount: $10M
- Date: 2026-04

## Document Inventory
- [Pitch Deck](pitch-deck.md) — 25 slides, company overview + traction
- [Financial Model](financial-model.md) — 5 tabs, 3-year projections
- [Cap Table](cap-table.md) — current ownership + option pool

## Key Findings
- Revenue growing 30% MoM for last 6 months
- CAC payback period: 4 months
- Net retention: 135%

## Bull Case
- Strong product-market fit signal (NPS 72)
- Expanding into adjacent vertical

## Bear Case
- Single customer represents 40% of revenue
- Burn rate increased 3x last quarter

## Open Questions
- What's the path to profitability?
- How defensible is the moat?
```

### Step 7: Enrich Company Brain Page

Update `brain/companies/{slug}.md`:
- Add document sources to frontmatter
- Update compiled truth with key findings
- Add "See Also" link to diligence directory
- If no company page exists, create one via the enrich skill

### Step 8: Commit

```bash
cd brain/ && git add -A && git commit -m "diligence: {Company} — {doc type} ingestion" && git push
```

### Step 9: Publish (if asked)

When the user wants a shareable brief, create a password-protected
published version. Strip internal notes and raw assessment language.

## Quality Bar

A good diligence page reads like an intelligence assessment:
- **What they say** vs **what the data shows** (the gap is the insight)
- Explicit bull/bear case (not just a summary)
- Key metrics highlighted, not buried
- Open questions that need answers before decision

---

*Part of the [GBrain Skillpack](../GBRAIN_SKILLPACK.md). See also: [Content & Media Ingestion](content-media.md), [Enrichment Pipeline](enrichment-pipeline.md)*
