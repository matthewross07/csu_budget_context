# Understanding CSU's FY27–28 Operating Budget Gap (`csu_budget_context`)

A reproducible **R (`4.5.2`) + Quarto (`1.10`)** primary-source financial reference examining Colorado State University’s (Fort Collins) projected **\$61.3M–\$70.7M FY27–28 operating budget gap** across two ledgers: near-term FY28 operating drivers (**Ledger A**) and multi-year structural cost and revenue context (**Ledger B**).

## Topline Finding

In official FY26 E&G budgets (`$885.16M`), Athletics general-fund support (`B2`: `$17.15M`, `1.9%`) and central capital debt service (`XA`: `$31.86M`, `3.6%`) together represent **5.5% (`$49.02M`) of CSU's annual E&G budget** and **8.0% (`+$29.16M` of `+$364.50M`) of 10-year E&G growth (`FY15–FY26`)**. Combined with recent one-time executive transition payouts (`$1.10M` presidential + `$0.325M` provost = `$1.43M`, or `2.2%` of one year's midpoint FY28 gap), eliminating 100% of those headline items would still leave **roughly `~$49M–$50M/yr` (~76% of the `$66.0M` FY28 gap)** unresolved. At the same time, cross-checking continuous `CDHE Format 30` data against CSU's 2018–19 Faculty Manual reclassification confirms that continuous E&G Faculty FTE grew only **`+7.2%` (`FY17–FY26`)** while E&G Administrative Professional FTE rose **`+62.3%` (`FY15–FY25`, including `+30.6%` after FY22)**.

## Substantive Verification & AI Disclosure

This repository was assembled using **Google DeepMind’s Antigravity** coding agent in R and Quarto, anchored by five analytical verification checks:

1. **Zero unverified LLM numbers:** Every chart and table is computed deterministically by R scripts (`src/02`–`src/04`) from 70 archived primary public filings and federal API extracts (`data/sources_manifest.csv` with SHA-256 hashes).
2. **Multi-ledger accounting triangulation:** Metrics are cross-checked across independent filings (`ColOBS` vs. Colorado State Auditor NCAA `2516F-B`; `Fact Book` FTE vs. continuous `CDHE Format 30`; CSU System Audits vs. IPEDS).
3. **Testing and overturning initial assumptions:** Triangulating `CDHE Format 30` against the April 2018 Faculty Manual Section E reform (`Special/Temporary → CCA`) overturned the initial assumption that rapid faculty hiring drove E&G expansion, showing continuous E&G Faculty growth was small (`+7.2%`, `FY17–FY26`) compared with post-FY22 E&G Admin Pro hiring (`+30.6%`).
4. **Separating self-supporting grants & controlling transfers:** Isolates the `69.7%` of Administrative Professional FTE funded outside E&G (`Sponsored Programs`, `Other Funds`, `Recharge Centers`, `Auxiliaries` in `Table 123–124`), and controls for FY19's `$41.64M` aid move and FY26's `$111.26M` fringe decentralization.
5. **Open code & programmatic assertions (`src/05_verify_audit.R`):** Automated reconciliation checks verify every bridge sum, fund split, and E&G partition on every build.

## Repository Structure

```text
CSU_finance/
├── _quarto.yml                 # Multi-page Quarto website config -> docs/ (non-indexed)
├── robots.txt                  # Disallow: / (crawler exclusion)
├── .nojekyll                   # Direct static serving on GitHub Pages
├── styles.scss                 # Visual theme
├── index.qmd                   # Overview, Topline Takeaway & Verification Summary
├── ledger-a-fy28-cliff.qmd     # Ledger A: Immediate FY28 Operating Gap Decomposition
├── ledger-b-structural.qmd     # Ledger B: Reconciled E&G Workforce, Non-E&G Separation & State Limits
├── athletics-audit.qmd         # Athletics Gross-vs.-Net Support, Bonded Debt & Counterfactuals
├── governance-and-peers.qmd    # Governance Transitions, Source Checks & IPEDS FY23 Peers
├── methodology-sources.qmd     # Verification Framework, Accounting Scope & 70-Source Ledger
├── report.qmd                  # Standalone 12-page PDF Brief -> outputs/pdf/CSU_Budget_Context_FY27_28.pdf
├── src/                        # Reproducible R scripts (00_setup..05_verify + report_helpers.R)
├── data/
│   ├── raw/                    # Gitignored locally (re-fetched via src/01_fetch_sources.R)
│   ├── processed/              # Analysis-ready CSVs tracked in repo
│   └── sources_manifest.csv    # Exact URLs, SHA-256 hashes, timestamps, page/table citations
├── outputs/                    # 300-DPI PNG + SVG figures & compiled PDF brief
├── docs/                       # Rendered static GitHub Pages site (non-indexed)
└── DATA_GAPS.md                # Portal restrictions & scope documentation
```
