# Understanding CSU's FY27–28 Operating Budget Gap (`csu_budget_context`)

A reproducible R (`4.5.2`) and Quarto (`1.10`) primary-source reference examining Colorado State University’s (Fort Collins) projected **\$61.3M–\$70.7M FY27–28 operating budget gap** across two financial ledgers: near-term FY28 operating drivers (**Ledger A**) and multi-year structural cost and revenue context (**Ledger B**), including an explicit separation of externally and self-funded research, clinical, extension, and auxiliary personnel from general-fund (E&G) budgets.

## How This Was Built & Reality Checks

Compiled by Matthew R.V. Ross using **Google DeepMind’s Antigravity** coding agent in R and Quarto as an open-source effort to understand CSU’s primary financial documents ahead of late-2026 campus meetings—shared humbly with full code and data so colleagues across faculty, staff, and administration can inspect, question, or improve any part of it. Six verification checks were applied:

1. **Primary-source-only ingestion:** Every table and figure derives programmatically from 70 public PDFs, governance memos, and federal/BLS API datasets archived and SHA-256 checksummed in `data/sources_manifest.csv`.
2. **Visual inspection of posted slide decks:** Rasterized slides identified blank white table placeholders in the online Oct. 14, 2026 PDF (Slides 14–15), so Ledger A relies exclusively on the Oct. 7, 2026 campus memo and May 13, 2026 V4 Slide 6 rather than estimating values.
3. **Externally funded research, clinical & auxiliary separation:** Separates non-E&G Administrative Professional FTE (`69.7%` campus-wide across `Sponsored Programs`, `Other Funds`, `Recharge Centers`, and `Auxiliaries`) from general-fund E&G positions (`Table 124`).
4. **Accounting reclassification controls:** Controls explicitly for FY19's `$41.64M` aid transfer (`XA` to `P1`) and FY26's `~$111.26M` central fringe benefit decentralization in ColOBS.
5. **Two-way fact-checking & non-interpolation:** Reviews claims across multiple viewpoints symmetrically against public filings, notes where public reporting on personnel involved universities other than CSU, and leaves omitted `FY21–FY24` E&G State Classified rows in Fact Book Table 128 as `NA`.
6. **Automated audit assertions (`src/05_verify_audit.R`):** Seven programmatic checks verify bridge sums, FTE splits, OSA balances, and figure outputs on every run.

## Repository Structure

```text
CSU_finance/
├── _quarto.yml                 # Multi-page Quarto website config -> docs/ (GitHub Pages, non-indexed)
├── robots.txt                  # Disallow: / (prevents search engine indexing)
├── .nojekyll                   # Direct static file serving on GitHub Pages
├── styles.scss                 # Calm editorial theme (CSU forest green, slate, gold, muted rust)
├── index.qmd                   # Overview, Two Ledgers & Build/Reality-Check Disclosure
├── ledger-a-fy28-cliff.qmd     # Ledger A: Immediate FY28 Projected Gap Decomposition
├── ledger-b-structural.qmd     # Ledger B: E&G vs. Non-E&G Workforce, State Funding & Discounting
├── athletics-audit.qmd         # Athletics Gross-vs.-Net Support, Long-Term Debt & Counterfactuals
├── governance-and-peers.qmd    # Governance Context, Source Verification & IPEDS FY23 Peers
├── methodology-sources.qmd     # How This Was Built, Reality Checks, Data Gaps & 70-Source Ledger
├── report.qmd                  # Standalone PDF Brief -> outputs/pdf/CSU_Budget_Context_FY27_28.pdf
├── src/
│   ├── 00_setup_theme.R        # Packages, csu_colors palette, theme_csu()
│   ├── 01_fetch_sources.R      # Primary document downloads -> data/raw/ & data/sources_manifest.csv
│   ├── 02_parse_and_clean.R    # PDF/HTML/API extraction -> data/processed/
│   ├── 03_analysis_metrics.R   # CPI-U real series, structural weights, non-E&G splits & Athletics math
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
