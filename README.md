# Understanding CSU's FY27–28 Operating Budget Gap (`csu_budget_context`)

A reproducible **R (`4.5.2`) + Quarto (`1.10`)** primary-source financial reference examining Colorado State University’s (Fort Collins) projected **\$61.3M–\$70.7M FY27–28 operating budget gap** across two ledgers: near-term FY28 operating drivers (**Ledger A**, including Nov. 3, 2026 Colorado ballot fiscal impacts) and multi-year structural cost and revenue context (**Ledger B**).

## Topline Finding

In official FY26 E&G budgets (`$885.16M`), Athletics general-fund support (`B2`: `$17.15M`, `1.9%`) and central capital debt service (`XA`: `$31.86M`, `3.6%`) together represent **5.5% (`$49.02M`) of CSU's annual E&G budget** and **8.0% (`+$29.16M` of `+$364.50M`) of 10-year E&G growth (`FY15–FY26`)**. Combined with recent one-time executive transition payouts (`$1.10M` presidential + `$0.325M` provost = `$1.43M`, or `2.2%` of one year's midpoint FY28 gap), eliminating 100% of those headline items would still leave **roughly `~$49M–$50M/yr` (~76% of the `$66.0M` FY28 gap)** unresolved. At the same time, continuous `CDHE Format 20/1100–1700` data establish that total E&G Faculty and Staff FTE grew **`+7.0%` (`FY15–FY26`)**, matching total Student FTE growth (`+6.6%`), while `85.5%` of E&G Non-Classified (`Admin Pro`) staff sit in Academic Support (`484.1` FTE), Instruction (`326.4` FTE staff who teach/run labs), Student Services (`204.8`), Research/Public Service (`190.6`), and Plant (`50.1`) rather than Central General Administration (`Format 1600`: `239.1` total FTE, `6.4%` of E&G FTE, declining to `187.4` in `FY27 Estimate`). Post-election passage of Colorado **Amendment 87 (`+$1.97B` FY28)** and **Proposition NN (`+$521M` FY28)** eases pre-election Medicaid/K-12 crowding on the State General Fund without directly funding E&G instruction.

## Verification & Reproducibility Safeguards

This repository was assembled with **Google DeepMind’s Antigravity** coding agent in R and Quarto, anchored by five verification checks:

1. **Deterministic code over checksummed filings:** Every chart and table is computed programmatically by R scripts (`src/02`–`src/04`) from 71 archived primary public filings, ballot fiscal notes, and federal API extracts (`data/sources_manifest.csv` with SHA-256 hashes).
2. **Isolating E&G general-fund positions from self-supporting grants & auxiliaries:** Separates the `69.7%` of Administrative Professional FTE funded outside E&G (`Sponsored Programs`, `Other Funds`, `Recharge Centers`, `Auxiliaries` in `Table 123–124`)—alongside `Proposition 137`'s dedicated non-E&G `CSFS` wildfire funds (`up to $36.5M–$42.8M/yr`).
3. **Functional E&G disaggregation & HR title reconciliation:** Cross-checks `CDHE Formats 20, 25, 30 & 1100–1700` and continuous `Fact Book FY26` series (`pp. 107–113`) to control for `-254.6` `State Classified -> AP/Recharge` shifts, `2018–19` `Special/Temporary -> CCA` rank formalization, and instructional/advising AP roles (`85.5%` of E&G AP) versus `Format 1600` Central General Administration (`6.4%` of E&G FTE).
4. **Normalizing accounting transfers & gross-vs.-net offsets:** Controls for FY19's `$41.64M` aid move (`XA` to `P1`) and FY26's `$111.26M` fringe decentralization in `ColOBS`, and reconciles `$75.24M` gross Athletics outlays (`OSA 2516F-B`) down to `~$15.57M` net operating support.
5. **Open code & programmatic assertions (`src/05_verify_audit.R`):** Automated verification assertions check every bridge sum, functional E&G identity, and fund partition on every build.

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
