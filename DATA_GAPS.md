# Data Gaps, Portal Blocks, and Accounting Scope Notes

Every figure, table, and claim in this project traces back to a primary source archived and SHA-256 hashed in `data/sources_manifest.csv` (`70/70` downloaded sources, `0` failed downloads after fallback routing). In keeping with strict auditability rules—no guessing, no silent interpolation, and no bypassing access controls—all upstream portal blocks, blank slide exports, and cross-year accounting breaks are documented below alongside exact manual download URLs where relevant.

---

## 1. Automated Access Blocks (`HTTP 403 Forbidden`)

| Target Source | Automated Behavior | Primary / Audited Fallback Used | Exact Manual Download URL(s) |
| :--- | :--- | :--- | :--- |
| **Knight-Newhouse College Athletics Database** | Returned `HTTP 403 Forbidden` to automated `httr2` / `curl` requests (anti-bot protection). | **Colorado Office of the State Auditor (OSA) Statutory NCAA Agreed-Upon Procedures (AUP) Reports**: `csu_ncaa_aup_fy19.pdf` through `csu_ncaa_aup_fy25.pdf` (`2516F-B` for FY25) plus CU Boulder `cub_ncaa_aup_fy25.pdf` (`2505F-B`). These are the underlying audited NCAA financial filings that Knight-Newhouse ingests. | [CSU Knight-Newhouse Profile](https://knightnewhousedata.org/fbs/mwc/colorado-state-university)<br>[Knight-Newhouse Data Download Form](https://knightnewhousedata.org/form/data-download) |
| **U.S. Government Accountability Office (`GAO-26-108640`)** | Returned `HTTP 403 Forbidden` when fetching the PDF directly from `gao.gov`. | Retrieved the published summary metrics (`nocap_gao_26_108640_summary.html`, AY 2023–24 Power-4 median `$120.3M` vs. Other FBS/G5 median `$21.0M`) alongside audited OSA NCAA AUP filings for CSU (`$206.96M` debt) and CU Boulder (`$177.02M` debt). | [GAO-26-108640 Full Report PDF](https://www.gao.gov/assets/gao-26-108640.pdf) |

---

## 2. Hostname & Posted Document Limitations

1. **IRP&E Bare Domain DNS (`ir.colostate.edu`):**
   - Requests to `https://ir.colostate.edu/` without the `www.` prefix fail DNS resolution. All IRP&E Fact Books (`CSU_Factbook_FY27_2026-10-22.pdf`, `CSU_Factbook_FY26.pdf`), BOG Fall Retention Reports (`2026-09-24_BOG_Fall_Report_Retention.pdf`), and Institutional Profiles (`Institutional-Profile-2024-2025.pdf`) were retrieved cleanly via `https://www.ir.colostate.edu/`.
2. **Oct. 14, 2026 Fall Budget Forum Slides (`Fall-Budget-Forum-Slides-10.14.26.pdf`, Slides 14–15):**
   - Visual inspection of rendered page images confirmed that Slides 14–15 in the publicly posted PDF contain blank white table placeholders where the FY28 scenario table sat during the live presentation.
   - *Mitigation:* Rather than reconstructing hidden slide pixels, the FY28 shortfall bridge (`$61.30M–$70.70M`, midpoint `$66.00M`), enrollment/tuition drop (`~$25.00M`), and Fall 2026 Resident Instruction headcount/credit-hour deltas rely strictly on the **Oct. 7, 2026 CSU Source Budget Update Memo** and the **May 13, 2026 Campus V4 Forum Slide 6** (`$15,112,000` in expiring one-time stopgap savings).
3. **CSU Fact Book FY27 Table 128 (`State Classified` E&G FTE Gap FY21–FY24):**
   - Table 128 in `CSU_Factbook_FY27_2026-10-22.pdf` omits E&G-only State Classified FTE rows for FY21–FY24 while reporting FY15–FY20 (`571.3` in FY15) and FY25 (`316.7`, a `-44.6%` decline vs. FY15).
   - *Mitigation:* FY21–FY24 E&G State Classified values are left uninterpolated (`NA`), and longitudinal workforce comparisons either anchor on FY15 vs. FY25 E&G endpoints or show all-funds Table 122/123 totals explicitly.

---

## 3. Scope, Lag, and Structural Accounting Breaks

1. **System vs. Fort Collins Campus Scope (`finstmt2015.pdf` – `finstmt2025.pdf`):**
   - CSU System Audited Financial Statements aggregate CSU Fort Collins, CSU Pueblo, and CSU System/SPUR operations (reporting `$644.9M` net tuition, `$174.1M` scholarship allowance, `21.3%` discount rate, and `$1,330.7M` long-term debt in FY25, plus `$79.1M` STRATA ATLAS Laser bonds issued June 26, 2025).
   - *Campus Isolation:* Fort Collins standalone long-term debt (`$1,118.77M` in FY25, of which `$206.96M` / `18.5%` is Athletics) is verified from Note 5 of `csu_ncaa_aup_fy25.pdf` (`2516F-B`); Fort Collins E&G operating budgets and student FTEs come from CDHE Format 30/20 Budget Data Books (`FINAL_BDB_FY15-16` through `FY26-27`) and College/Division Operating Budget Summaries (`FY15`–`FY26`); Fort Collins employee FTEs by fund come from IRP&E Fact Books.
2. **College & Division Operating Budget Summary (`ColOBS`) Reclassifications (`FY15`–`FY26`):**
   - **FY19 Aid Shift:** `$41.64M` of institutional financial aid moved from Central (`XA Central`) into `P1 Enrollment & Access`.
   - **FY26 Fringe Decentralization:** `~$111.26M` of centrally pooled `XA Employee Fringe Benefits` was pushed out into individual academic colleges and support divisions in FY26. Division-share analyses explicitly account for both shifts rather than mislabeling an accounting reclassification as organic administrative growth.
3. **IPEDS Peer Series Reporting Lag (`2015–2023`):**
   - Urban Institute's IPEDS Finance and Human Resources API endpoints provide harmonized cross-institution series through academic/fiscal year **2023** (`peer_benchmarks_2023.csv`). For FY25 Athletics comparisons, peer benchmarks pair FY23 IPEDS (`CU Boulder`, `Mines`, `Oregon State`, `Washington State`, `Utah State`, `Kansas State`, `Iowa State`) with FY25 statutory OSA AUP filings (`CSU` `2516F-B` and `CU Boulder` `2505F-B`).
4. **BLS CPI-U Partial FY27 Coverage (`bls_cpiu_2014_2026.csv`):**
   - BLS series `CUUR0000SA0` spans January 2014 through October 2026 (`accessed 2026`), providing complete fiscal-year averages for FY15–FY26 and a 4-month (`Jul–Oct 2026`) partial window for FY27. Inflation-adjusted (`FY25-real` / `FY26-real`) trend analyses use full fiscal-year CPI-U denominators through FY25/FY26.
