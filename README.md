# Understanding CSU's FY27–28 Operating Budget Gap (`csu_budget_context`)

A reproducible R (`4.5.2`) and Quarto (`1.10`) primary-source reference analyzing Colorado State University’s (Fort Collins) projected **\$61.3M–\$70.7M FY27–28 operating budget gap** across two ledgers: immediate FY28 drivers (**Ledger A**) and multi-year structural cost/revenue constraints (**Ledger B**), including an explicit separation of soft-money research personnel (e.g., WCNR/CEMML, Engineering/CIRA, CVMBS) from general-fund (E&G) overhead.

## How This Was Built & Reality Checks

Initiated, framed, and reviewed by Matthew R.V. Ross (CSU) using **Google DeepMind’s Antigravity** agentic coding environment. Six verification guardrails are built into the pipeline:

1. **Primary-source-only ingestion:** Every table and figure derives programmatically from 70 public PDFs, governance memos, and federal/BLS API datasets archived and SHA-256 checksummed in `data/sources_manifest.csv`.
2. **Visual inspection of posted slide decks:** Rasterized slides identified blank white table placeholders in the online Oct. 14, 2026 PDF (Slides 14–15), so Ledger A relies exclusively on the Oct. 7, 2026 campus memo and May 13, 2026 V4 Slide 6 rather than estimating values.
3. **Soft-money research separation (CEMML / CIRA / VTH):** Separates externally/self-funded Administrative Professional FTE (`69.7%` campus-wide; `96.3%` in WCNR/CEMML) from general-fund E&G positions (`Table 124`).
4. **Accounting reclassification controls:** Controls explicitly for FY19's `$41.64M` aid shift (`XA` to `P1`) and FY26's `~$111.26M` central fringe benefit decentralization in ColOBS.
5. **Two-way fact-checking & non-interpolation:** Verifies circulating claims symmetrically (flagging that public *San Francisco Chronicle* Title IX reporting on Jeffrey Lamoureaux involved other universities rather than CSU, and leaving omitted `FY21–FY24` E&G State Classified rows in Fact Book Table 128 as `NA`).
6. **Automated audit assertions (`src/05_verify_audit.R`):** Seven programmatic checks verify bridge sums, FTE splits, OSA balances, and figure outputs on every run.

## Repository Structure

```text
CSU_finance/
├── _quarto.yml                 # Multi-page Quarto website config -> docs/ (GitHub Pages, non-indexed)
├── robots.txt                  # Disallow: / (prevents search engine indexing)
├── .nojekyll                   # Direct static file serving on GitHub Pages
├── styles.scss                 # Calm editorial theme (CSU forest green, slate, gold, muted rust)
├── index.qmd                   # Overview, Two Ledgers & Build/Reality-Check Disclosure
├── ledger-a-fy28-cliff.qmd     # Ledger A: Immediate FY28 Shortfall Decomposition
├── ledger-b-structural.qmd     # Ledger B: E&G vs. Non-E&G (CEMML) Workforce, State Funding & Discounting
├── athletics-audit.qmd         # Athletics Gross-vs.-Net Support, $206.96M Debt & Counterfactuals
├── governance-and-peers.qmd    # Trust & Governance Context, Source Check & IPEDS FY23 Peers
├── methodology-sources.qmd     # How This Was Built, Reality Checks, Data Gaps & 70-Source Ledger
├── report.qmd                  # Standalone PDF Brief -> outputs/pdf/CSU_Budget_Context_FY27_28.pdf
├── src/
│   ├── 00_setup_theme.R        # Packages, csu_colors palette, theme_csu()
│   ├── 01_fetch_sources.R      # Primary document downloads -> data/raw/ & data/sources_manifest.csv
│   ├── 02_parse_and_clean.R    # PDF/HTML/API extraction -> data/processed/
│   ├── 03_analysis_metrics.R   # CPI-U real series, structural weights, CEMML & Athletics math
│   ├── 04_make_figures.R       # Generates 6 PNG + SVG figures -> outputs/figures/
│   ├── 05_verify_audit.R       # Seven automated accounting & manifest assertions
│   ├── report_helpers.R        # Shared gt / kableExtra / formatting helpers for HTML & PDF
│   └── run_all.R               # Runs src/00..05 end-to-end
├── data/
│   ├── raw/                    # Gitignored locally (re-fetched cleanly via src/01_fetch_sources.R)
│   ├── processed/              # Clean, analysis-ready CSVs tracked in repo
│   └── sources_manifest.csv    # Exact URLs, SHA-256 hashes, timestamps, page/table citations
├── outputs/
│   ├── figures/                # 300-DPI PNG and vector SVG charts
│   └── pdf/                    # Compiled PDF brief
├── docs/                       # Rendered static GitHub Pages site (non-indexed)
└── DATA_GAPS.md                # Portal restrictions (HTTP 403) & accounting scope notes
```

## Reproduction

```bash
Rscript src/run_all.R
quarto render report.qmd --to pdf
mv CSU_Budget_Context_FY27_28.pdf outputs/pdf/CSU_Budget_Context_FY27_28.pdf
quarto render
```
