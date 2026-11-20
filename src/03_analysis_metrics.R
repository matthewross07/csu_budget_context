# 03_analysis_metrics.R
# Computes inflation-adjusted series, E&G vs. Non-E&G (CEMML/Research) FTE indices,
# Ledger B Blame Pie decompositions, Athletics Gross-to-Net reconciliation,
# NCAA Black Swan math, division budget shares, and IPEDS peer benchmarks.

source(file.path(if (dir.exists("src")) "src" else ".", "00_setup_theme.R"))

raw_dir  <- file.path(PROJECT_ROOT, "data", "raw")
proc_dir <- file.path(PROJECT_ROOT, "data", "processed")

cpi_fy    <- read_csv(file.path(proc_dir, "macro_cpiu_fy.csv"), show_col_types = FALSE)
fte_fund  <- read_csv(file.path(proc_dir, "fte_by_fund_fy13_fy25.csv"), show_col_types = FALSE)
ap_unit   <- read_csv(file.path(proc_dir, "ap_fte_by_unit_fy25.csv"), show_col_types = FALSE)
bdb       <- read_csv(file.path(proc_dir, "bdb_eg_summary_fy17_fy27.csv"), show_col_types = FALSE)
bdb_func  <- read_csv(file.path(proc_dir, "bdb_format20_functional_eg_fy15_fy27.csv"), show_col_types = FALSE)
fb26_cont <- read_csv(file.path(proc_dir, "factbook_continuous_eg_fte_fy13_fy25.csv"), show_col_types = FALSE)
eg_div    <- read_csv(file.path(proc_dir, "eg_division_budgets_fy17_fy26.csv"), show_col_types = FALSE)
audits    <- read_csv(file.path(proc_dir, "audits_system_fy15_fy25.csv"), show_col_types = FALSE)
ath_csu   <- read_csv(file.path(proc_dir, "athletics_ncaa_csu_fy19_fy25.csv"), show_col_types = FALSE)
ipeds     <- read_csv(file.path(proc_dir, "peer_ipeds_panel_2015_2023.csv"), show_col_types = FALSE)
fy28_b    <- read_csv(file.path(proc_dir, "fy28_shortfall_bridge.csv"), show_col_types = FALSE)

# ==============================================================================
# 1. E&G WORKFORCE VS. NON-E&G (CEMML/RESEARCH) VS. STUDENT DEMAND (2015-2025/26)
# ==============================================================================
message("--- Computing 1: E&G Workforce Overshoot & CEMML/Research Split ---")

# Group Fact Book employee categories into clear governance cohorts
fte_cohorts <- fte_fund |>
  filter(fiscal_year >= 2015L, fiscal_year <= 2025L) |>
  mutate(
    cohort = case_when(
      employee_group == "Administrative Professional" ~ "Admin Professional",
      employee_group %in% c("Tenured Faculty", "Tenure-Track Faculty") ~ "Tenured & TT Faculty",
      employee_group %in% c("Contract Faculty", "Continuing Faculty", "Adjunct Faculty", "Transitional Faculty") ~ "NTT / CCA & Adjunct Faculty",
      employee_group == "State Classified" ~ "State Classified Staff",
      employee_group == "Graduate Assistant" ~ "Graduate Assistant"
    )
  ) |>
  group_by(fiscal_year, cohort) |>
  summarise(
    eg_fte = ifelse(all(is.na(eg_fte)), NA_real_, sum(eg_fte, na.rm = TRUE)),
    other_funds_fte = ifelse(all(is.na(other_funds_fte)), NA_real_, sum(other_funds_fte, na.rm = TRUE)),
    total_fte = sum(total_fte, na.rm = TRUE),
    .groups = "drop"
  )

# Reshape cleanly into long series comparing E&G-funded cohorts, Non-E&G AP (research/aux),
# Resident vs Non-Resident Student FTE (from BDB FY17-27 + Factbook/Audits), and Real Net Tuition
eg_wide <- fte_cohorts |>
  select(fiscal_year, cohort, eg_fte, other_funds_fte, total_fte)

# Construct E&G-only indexed series (Base 2015 = 100 for employee FTE; Base 2017 = 100 for BDB Student FTE where FY15-16 BDB absent)
# Note: Check if Student FTE FY15-16 exists in Fact Book or IPEDS FTE so we have continuous 2015=100!
# Let's pull CSU IPEDS rep_fte/est_fte for 2015-2023 AND BDB Student FTE for 2017-2026!
csu_real_tuition <- audits |>
  left_join(cpi_fy |> select(fy, mult_to_fy25), by = c("fiscal_year" = "fy")) |>
  mutate(
    real_net_tuition_fy25m = system_net_tuition_m * mult_to_fy25,
    real_debt_fy25m = system_total_debt_m * mult_to_fy25,
    real_ffs_fy25m = system_ffs_m * mult_to_fy25
  )

# Build Panel A dataset (FY2015-FY2025, indexed 2015 = 100 where available, and FY17-FY26 Student FTE indexed to 2017 = 100 OR joined at 2017)
# Wait: Fact Book FY27 p.5 gives Total Fall Headcount 2015-2026; let's check BDB FY17-27 Resident vs NR FTE!
# Even cleaner: BDB starts FY17 (Actual 2016-17), whereas Fact Book Employee FTE covers FY13-FY25.
# Index ALL series in Panel A to FY2017 = 100 (or show FY15-25 Employee FTE indexed to FY15=100 AND Student FTE FY17-26 indexed to FY17=100? Wait: indexing everything to FY17 = 100 OR pulling FY15-16 Student FTE from IPEDS/FB!)
# Wait: Using FY2017 = 100 makes EVERY series (E&G Admin Pro, E&G T/TT, E&G NTT/CCA, E&G State Classified, Non-E&G Admin Pro, Resident Student FTE, Non-Resident Student FTE, Real Net Tuition) share the EXACT SAME base year (FY2017 = 100) AND we also compute 10-year FY15->FY25 deltas in summary tables!
# Wait: the prompt specifically mentions "Indexing to 2015 = 100". Let's check if we can compute exact FY2015 & FY2016 student FTE from CSU Fact Book / IPEDS OR check Fact Book Student FTE!
# Earlier we saw IPEDS `ipeds_fte_2015_2023.csv` has `2015`..`2023` FTE for CSU (`126818`), and `audits_system_fy15_fy25.csv` starts at `FY2015`!
# Let's check `fte_by_fund` at FY2015 vs FY2025 AND check whether FY2015-2025 E&G Admin Pro, E&G T/TT, E&G NTT/CCA, Real System Net Tuition, and Fall Headcount (2015=100) vs Resident/NR FTE (2017=100) match cleanly!
# Wait: Fact Book Table 1 (p.5) gives Fall Total Enrollment 2015-2026 AND IPEDS gives 2015-2023 FTE! Let's inspect `bdb` vs `ipeds` FTE at 2017 overlap right here so we don't splice silently.
csu_ipeds_fte <- ipeds |>
  filter(unitid == 126818) |>
  select(year, fte_best, rev_tuition_fees_net) |>
  arrange(year)

# Compute indexed trajectories cleanly at BOTH FY2015=100 (for Workforce, Real Net Tuition, Fall Headcount) and FY2017=100 (for BDB Resident vs Non-Resident Student FTE)
base15_emp <- fte_cohorts |>
  filter(fiscal_year == 2015L) |>
  select(cohort, base15_eg = eg_fte, base15_other = other_funds_fte, base15_tot = total_fte)

workforce_idx <- fte_cohorts |>
  left_join(base15_emp, by = "cohort") |>
  mutate(
    idx15_eg = 100 * eg_fte / base15_eg,
    idx15_other = 100 * other_funds_fte / base15_other,
    idx15_tot = 100 * total_fte / base15_tot
  )

write_csv(workforce_idx, file.path(proc_dir, "workforce_cohorts_fy15_fy25.csv"))

# Also save combined All-E&G vs All-Other-Funds totals (excluding State Classified FY21-24 NA artifact by tracking ex-SC and including FY25 exact SC=316.7)
eg_totals_summary <- fte_cohorts |>
  group_by(fiscal_year) |>
  summarise(
    eg_all_incl_ga = sum(eg_fte, na.rm = TRUE),
    eg_perm_ex_ga = sum(eg_fte[cohort != "Graduate Assistant"], na.rm = TRUE),
    eg_faculty_total = sum(eg_fte[cohort %in% c("Tenured & TT Faculty", "NTT / CCA & Adjunct Faculty")], na.rm = TRUE),
    eg_faculty_ttt = sum(eg_fte[cohort == "Tenured & TT Faculty"], na.rm = TRUE),
    eg_faculty_ntt = sum(eg_fte[cohort == "NTT / CCA & Adjunct Faculty"], na.rm = TRUE),
    eg_admin_pro = sum(eg_fte[cohort == "Admin Professional"], na.rm = TRUE),
    eg_state_class = sum(eg_fte[cohort == "State Classified Staff"], na.rm = TRUE),
    other_admin_pro = sum(other_funds_fte[cohort == "Admin Professional"], na.rm = TRUE),
    other_all_fte = sum(other_funds_fte, na.rm = TRUE),
    total_all_funds_fte = sum(total_fte, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    # Clean State Classified E&G gap flag
    eg_state_class = ifelse(fiscal_year %in% 2021:2024, NA_real_, eg_state_class),
    eg_perm_ex_ga  = ifelse(fiscal_year %in% 2021:2024, NA_real_, eg_perm_ex_ga)
  )
write_csv(eg_totals_summary, file.path(proc_dir, "eg_vs_noneg_workforce_totals.csv"))

# Unit-level CEMML / Soft-Money breakdown (FY25 AP FTE Table 124)
ap_unit_summary <- ap_unit |>
  mutate(
    macro_bucket = case_when(
      unit == "Warner College of Natural Resources" ~ "Warner College of Natural Resources",
      unit == "Veterinary Medicine & Biomedical Sci" ~ "Veterinary Med. & Biomedical Sci.",
      unit == "Walter Scott Jr College of Engr" ~ "Walter Scott, Jr. College of Engineering",
      unit %in% c("Agricultural Sciences", "Agric Sciences-Agric Experiment Station",
                  "CSU Extension", "Natural Resources-Colo State Forest Svc") ~ "Ag Sciences, AES, Extension & CSFS",
      unit %in% c("Business", "Liberal Arts", "Natural Sciences", "Health and Human Sciences", "Libraries") ~ "Other Academic Colleges & Libraries",
      unit %in% c("President's Office-Athletics", "President's Office-Athletic Compliance") ~ "Athletics & Compliance",
      grepl("^VPSA", unit) ~ "Student Affairs, Housing & Rec",
      TRUE ~ "Central VP Divisions, Admin & SPUR"
    )
  ) |>
  group_by(macro_bucket) |>
  summarise(
    eg_fte = sum(eg_fte, na.rm = TRUE),
    other_funds_fte = sum(other_funds_fte, na.rm = TRUE),
    total_fte = sum(total_fte, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    non_eg_share = other_funds_fte / total_fte,
    eg_share_of_campus_eg = eg_fte / sum(eg_fte),
    source_id = "factbook_fy27"
  ) |>
  arrange(desc(total_fte))

write_csv(ap_unit_summary, file.path(proc_dir, "cemml_ap_unit_summary_fy25.csv"))

# ==============================================================================
# 1B. FUNCTIONAL E&G DISAGGREGATION (STAFF WHO TEACH VS. CENTRAL GENERAL ADMIN)
# ==============================================================================
message("--- Computing 1B: CDHE Functional E&G AP & Workforce Split (FY15-FY27) ---")

f15_fn <- bdb_func |> filter(fiscal_year == 2015L)
f24_fn <- bdb_func |> filter(fiscal_year == 2024L)
f26_fn <- bdb_func |> filter(fiscal_year == 2026L, status == "Actual")
f27_fn <- bdb_func |> filter(fiscal_year == 2027L, status == "Estimate")

eg_ap_func_split <- tribble(
  ~func_order, ~cdhe_format, ~nacubo_function, ~role_scope, ~ap_fy15, ~ap_fy24, ~ap_fy26, ~ap_fy27_est, ~tot_fy15, ~tot_fy26, ~tot_fy27_est, ~usd_fy26_m,
  1L, "Fmt 1400", "Academic Support", "Advising, student-success coordinators, libraries & instructional tech",
      f15_fn$acad_ap_fte, f24_fn$acad_ap_fte, f26_fn$acad_ap_fte, f27_fn$acad_ap_fte,
      f15_fn$acad_fte, f26_fn$acad_fte, f27_fn$acad_fte, round(f26_fn$acad_usd / 1e6, 2),
  2L, "Fmt 1100", "Instruction (Non-Faculty AP)", "Staff who teach, teaching-lab coordinators, clinical & dept. instructional roles",
      f15_fn$inst_ap_fte, f24_fn$inst_ap_fte, f26_fn$inst_ap_fte, f27_fn$inst_ap_fte,
      f15_fn$inst_fte, f26_fn$inst_fte, f27_fn$inst_fte, round(f26_fn$inst_usd / 1e6, 2),
  3L, "Fmt 1600", "Institutional Support (General Admin)", "Central executive, finance/budget, HR, legal & general administration",
      f15_fn$inst_supp_ap_fte, f24_fn$inst_supp_ap_fte, f26_fn$inst_supp_ap_fte, f27_fn$inst_supp_ap_fte,
      f15_fn$inst_supp_fte, f26_fn$inst_supp_fte, f27_fn$inst_supp_fte, round(f26_fn$inst_supp_usd / 1e6, 2),
  4L, "Fmt 1500", "Student Services", "Admissions, financial aid, registrar & student counseling/support",
      f15_fn$stud_ap_fte, f24_fn$stud_ap_fte, f26_fn$stud_ap_fte, f27_fn$stud_ap_fte,
      f15_fn$stud_fte, f26_fn$stud_fte, f27_fn$stud_fte, round(f26_fn$stud_usd / 1e6, 2),
  5L, "Fmt 1200-1300", "Research & Public Service (State E&G)", "State-supported E&G research centers & public service staff",
      f15_fn$res_ap_fte + f15_fn$pub_ap_fte, f24_fn$res_ap_fte + f24_fn$pub_ap_fte,
      f26_fn$res_ap_fte + f26_fn$pub_ap_fte, f27_fn$res_ap_fte + f27_fn$pub_ap_fte,
      f15_fn$res_fte + f15_fn$pub_fte, f26_fn$res_fte + f26_fn$pub_fte, f27_fn$res_fte + f27_fn$pub_fte,
      round((f26_fn$res_usd + f26_fn$pub_usd) / 1e6, 2),
  6L, "Fmt 1700", "Operation & Maintenance of Plant", "Facilities engineering, maintenance & E&G physical plant operations",
      f15_fn$plant_ap_fte, f24_fn$plant_ap_fte, f26_fn$plant_ap_fte, f27_fn$plant_ap_fte,
      f15_fn$plant_fte, f26_fn$plant_fte, f27_fn$plant_fte, round(f26_fn$plant_usd / 1e6, 2)
) |>
  mutate(
    ap_share_fy26 = ap_fy26 / sum(ap_fy26),
    ap_delta_15_26 = ap_fy26 - ap_fy15,
    tot_delta_15_26 = tot_fy26 - tot_fy15,
    tot_pct_15_26 = (tot_fy26 - tot_fy15) / tot_fy15,
    tot_share_fy26 = tot_fy26 / sum(tot_fy26),
    source_id = "cdhe_bdb_fy15_fy27"
  )

write_csv(eg_ap_func_split, file.path(proc_dir, "eg_ap_functional_split_fy15_fy26.csv"))

# ==============================================================================
# 2. REAL FINANCIAL SERIES (AUDITED + E&G BDB)
# ==============================================================================
message("--- Computing 2: CPI-Adjusted Real Tuition, State Support, & Debt ---")
real_audits <- csu_real_tuition |>
  mutate(
    idx15_real_net_tuition = 100 * real_net_tuition_fy25m / real_net_tuition_fy25m[fiscal_year == 2015L],
    idx15_real_debt = 100 * real_debt_fy25m / real_debt_fy25m[fiscal_year == 2015L]
  )
write_csv(real_audits, file.path(proc_dir, "real_audits_fy15_fy25.csv"))

bdb_real <- bdb |>
  left_join(cpi_fy |> select(fy, mult_to_fy26), by = c("fiscal_year" = "fy")) |>
  mutate(
    eg_total_tuition_real26_m = (eg_total_tuition / 1e6) * mult_to_fy26,
    eg_res_ug_tuition_real26_m = (eg_res_ug_tuition / 1e6) * mult_to_fy26,
    eg_nr_tuition_real26_m = (eg_nr_tuition / 1e6) * mult_to_fy26,
    eg_state_total_real26_m = ((eg_ffs_contracts + eg_cof_stipend) / 1e6) * mult_to_fy26,
    eg_scholarships_real26_m = (eg_scholarships / 1e6) * mult_to_fy26,
    nr_share_fte = nonresident_fte / total_student_fte,
    nr_share_tuition = eg_nr_tuition / eg_total_tuition,
    idx15_res_fte = 100 * resident_fte / resident_fte[fiscal_year == 2015L],
    idx15_nr_fte  = 100 * nonresident_fte / nonresident_fte[fiscal_year == 2015L],
    idx15_tot_student_fte = 100 * total_student_fte / total_student_fte[fiscal_year == 2015L],
    idx15_eg_tuition_real = 100 * eg_total_tuition_real26_m / eg_total_tuition_real26_m[fiscal_year == 2015L]
  )
write_csv(bdb_real, file.path(proc_dir, "bdb_real_fy17_fy27.csv"))

# ==============================================================================
# 3. DIVISION E&G BUDGET SHARES (FY17-FY26) — NORMALIZED FOR FY19 AID MOVE & FY26 FRINGE
# ==============================================================================
message("--- Computing 3: Normalized Division Budget Shares ---")
div_shares <- eg_div |>
  mutate(
    # In FY17-18, $41.6M institutional scholarships sat in Central Budgets; in FY19+, it moved to P1 (Academic Support).
    # In FY17-25, $77M-$111M of Employee Fringe Benefits sat in Central Budgets; in FY26, it was decentralized into units.
    colleges_share_raw = colleges_total / grand_total,
    pvm_agencies_share = pvm_agencies_total / grand_total,
    acad_support_ex_aid_share = academic_support_ex_aid / grand_total,
    support_plus_pres_share = (support_div_total + presidents_div_total) / grand_total,
    student_support_share = student_support_total / grand_total,
    central_share_raw = central_budgets_total / grand_total,
    inst_aid_share = inst_aid_budget_eg / grand_total,
    b2_athletics_share_eg = b2_athletics_eg / grand_total,
    xa_debt_share_eg = xa_debt_service / grand_total,
    fringe_decentralized_flag = is.na(xa_fringe_benefits)
  )
write_csv(div_shares, file.path(proc_dir, "division_budget_shares_fy17_fy26.csv"))

# ==============================================================================
# 4. ATHLETICS GROSS-TO-NET RECONCILIATION, DEBT PEERS, & BLACK SWAN MATH
# ==============================================================================
message("--- Computing 4: Athletics Gross vs Net, Debt Peers, & Black Swan Scenarios ---")
ath25 <- ath_csu |> filter(fiscal_year == 2025L)

# Waterfall / reconciliation from Gross FY25 Spending ($75.24M) to Net Institutional Operating Drag
ath_recon_fy25 <- tribble(
  ~step_id, ~component, ~amount_m, ~category, ~note,
  1L, "Total Athletics Operating Expenses",      -ath25$total_expenses / 1e6, "Gross Outflow",
      "FY25 OSA NCAA AUP total operating expenses ($75.24M; includes $14.34M debt service/leases, $12.75M coaching, $10.15M staff, $10.93M student aid).",
  2L, "Self-Generated External Revenue",          ath25$self_generated_rev / 1e6, "Earned Offset",
      "Tickets ($8.17M), Contributions ($12.01M), Sponsorships/Royalties ($6.70M), Conf/Media/NCAA ($8.17M), Concessions/Guarantees/Other ($7.54M).",
  3L, "Mandatory Student Athletics Fees",         ath25$student_fees / 1e6, "Student Fee Offset",
      "Dedicated student athletics fees ($6.14M, 8.2% of total revenue).",
  4L, "Direct & Indirect Institutional Support",  (ath25$direct_inst_support + ath25$indirect_inst_support) / 1e6, "University Support",
      "Direct support ($23.85M, incl. $16.91M E&G base B2 allocation + transfers) + Indirect support ($2.15M).",
  5L, "Reported Operating Deficit (FY25)",        ath25$excess_deficit / 1e6, "Net Accounting Balance",
      "Excess (Deficit) of Revenues over Expenses (-$0.50M).",
  6L, "Memo: Scholarship Tuition Flow-Back",      ath25$athletic_student_aid / 1e6, "Internal Campus Return",
      "Athletic Student Aid ($10.93M) paid back to campus for tuition/fees/room/board (reduces net economic cash drain).",
  7L, "Estimated Net Institutional Operating Support", -(ath25$direct_inst_support + ath25$indirect_inst_support - ath25$athletic_student_aid - ath25$excess_deficit) / 1e6, "Net University Support",
      "Gross Institutional Support ($26.00M) + Deficit ($0.50M) minus Tuition/Aid Flow-Back ($10.93M) = ~$15.57M net operating support (excl. student fees; ~$21.71M incl. student fees)."
)
write_csv(ath_recon_fy25, file.path(proc_dir, "athletics_gross_to_net_fy25.csv"))

# Athletics Debt Peer Benchmark (100% primary verified from OSA FY25 AUPs & GAO-26-108640)
ath_debt_peers <- tribble(
  ~entity, ~athletics_debt_m, ~debt_type, ~source_citation,
  "Colorado State University (FY25)",          round(ath25$athletics_debt / 1e6, 2), "Colorado OSA FY25 AUP (18.5% of CSU debt)", "Colorado OSA Report 2516F-B, Note 5 (p.26)",
  "CU Boulder: Bonds + Treasury Loan (FY25)",  177.02, "Colorado OSA FY25 AUP ($138.8M bonds + $38.2M loan)", "Colorado OSA Report 2505F-B, Note 5 (p.35)",
  "CU Boulder: External Bonds Only (FY25)",    138.83, "Colorado OSA FY25 AUP (7.5% of CU debt)", "Colorado OSA Report 2505F-B, Note 5 (p.35)",
  "Power Conference Median (AY23-24)",         120.30, "GAO-26-108640 Federal Benchmark", "U.S. GAO Report GAO-26-108640 (Power-4 median)",
  "Other FBS / Group of 5 Median (AY23-24)",    21.00, "GAO-26-108640 Federal Benchmark", "U.S. GAO Report GAO-26-108640 (Non-Power FBS median)"
)
write_csv(ath_debt_peers, file.path(proc_dir, "athletics_debt_peers.csv"))

# Counterfactual Athletics & Postseason Scenarios vs. Recurring Operating Gap
black_swan_math <- tribble(
  ~scenario, ~units_earned, ~annual_pool_payout_m, ~conference_split_members, ~annual_to_csu_m, ~pct_of_66m_gap, ~explanation,
  "NCAA Men's Basketball 1st Round Win (2 units)",        2, 0.340 * 2, 12, (0.340 * 2) / 12, ((0.340 * 2) / 12) / 66.0, "1st round appearance + 1 win = 2 units; paid over 6 yrs, split equally across ~12 conference members.",
  "NCAA Men's Basketball Final Four Run (5 units)",       5, 0.340 * 5, 12, (0.340 * 5) / 12, ((0.340 * 5) / 12) / 66.0, "5 games played/won prior to Final Four (pre-2026 rule) or up to 6-7 units under 2026 expansion: ~$0.14M/yr per campus.",
  "Hypothetical: Retaining 100% of 5 NCAA Units",         5, 0.340 * 5,  1, 0.340 * 5,        (0.340 * 5) / 66.0,        "Even without conference revenue sharing, 5 NCAA units yield ~$1.70M/yr for 6 years (~2.6% of FY28 gap).",
  "Hypothetical: Discontinuing Football Operations",     NA,        NA, NA, 15.6,             15.6 / 66.0,               "Frees ~$15.6M net institutional support (or $17.2M B2 E&G) BUT leaves $207.0M stadium/athletic bond debt service ($10.0M/yr) unpaid (~$45M-$50M residual FY28 gap)."
)
write_csv(black_swan_math, file.path(proc_dir, "black_swan_math.csv"))

# ==============================================================================
# 5. LEDGER B: MULTI-YEAR STRUCTURAL COST & REVENUE PRESSURES
# ==============================================================================
message("--- Computing 5: Ledger B Structural Attribution Ranges ---")
# Separates AUDITED BASELINE FACTS from ILLUSTRATIVE WEIGHTS (sum of midpoints = 100%)
structural_blame <- tribble(
  ~bucket_order, ~driver, ~low_pct, ~mid_pct, ~high_pct, ~audited_anchor, ~methodology_note,
  1L, "E&G Payroll Cost Inflation, Support Mix & Incremental Budgeting", 40, 45, 50,
      "Total E&G FTE grew +7.0% (3,506 -> 3,752, FY15-26, matching +6.6% Student FTE; Central General Admin Fmt 1600 = 239.1 FTE / 6.4% of E&G FTE, budgeted at 187.4 in FY27), while Academic + Student Support rose +39.9% (+224 FTE) and each 3% comp/fringe pool adds ~$33.7M/yr.",
      "Order-of-magnitude illustration reflecting the ~70%+ personnel share of E&G expenditures, cumulative benefit/wage inflation, and fixed base carry-forwards.",
  2L, "Long-Term Capital Commitments & Debt Service", 20, 22, 25,
      "CSU System Debt doubled from $671.9M (FY13) to $1,449.3M peak (FY23) / $1,330.7M (FY25) + $79.1M FY25 STRATA Laser bond. E&G Central Debt Service more than tripled from $10.2M (FY15) to $31.9M (FY26).",
      "Captures hard bond covenants, debt service, and new building O&M/utilities that remain fixed during enrollment dips.",
  3L, "Athletics Net Operating Subsidy (Excl. Bonded Debt)", 15, 17, 20,
      "Gross spending $75.24M (FY25), Direct+Indirect Univ Support $26.00M + $6.14M student fees, minus $10.93M athletic aid flow-back = ~$15.6M net institutional operating support (B2 E&G = $17.15M in FY26).",
      "Excludes $206.96M bonded athletic debt (counted in Bucket 2 to prevent double-counting) and student fees paid outside E&G.",
  4L, "State Funding Limits, Tuition Discounting & F&A Scope", 15, 16, 20,
      "FY27 State FFS+COF flat at $211.1M (23.4% of State Approp); System discount rate rose 17.9% (FY17) -> 21.3% (FY25, $174.1M); Nov. 2026 Amend. 87 (+$1.97B FY28) & Prop NN relieve K-12/Medicaid General Fund crowding but remain earmarked outside E&G instruction.",
      "Reflects state TABOR/Medicaid crowding prior to Nov. 2026 reforms + institutional merit aid competition for non-resident students."
)
write_csv(structural_blame, file.path(proc_dir, "structural_blame_pie.csv"))

# ==============================================================================
# 5B. TOPLINE TAKEAWAY SUMMARY (HEADLINE FLASHPOINTS VS. TOTAL E&G & FY28 GAP)
# ==============================================================================
message("--- Computing 5B: Topline Takeaway Scale Summary ---")
d15 <- eg_div |> filter(fiscal_year == 2015L)
d26 <- eg_div |> filter(fiscal_year == 2026L)

fy26_total_m   <- d26$grand_total / 1e6
fy26_ath_m     <- d26$b2_athletics_eg / 1e6
fy26_debt_m    <- d26$xa_debt_service / 1e6
fy26_acad_m    <- (d26$colleges_total + d26$pvm_agencies_total + d26$academic_support_ex_aid + (d26$student_support_total - d26$b2_athletics_eg)) / 1e6
fy26_admin_m   <- (d26$support_div_total + d26$presidents_div_total) / 1e6
fy26_aid_m     <- d26$inst_aid_budget_eg / 1e6
fy26_central_m <- fy26_total_m - (fy26_ath_m + fy26_debt_m + fy26_acad_m + fy26_admin_m + fy26_aid_m)

tot_grow_m     <- (d26$grand_total - d15$grand_total) / 1e6
ath_grow_m     <- (d26$b2_athletics_eg - d15$b2_athletics_eg) / 1e6
debt_grow_m    <- (d26$xa_debt_service - d15$xa_debt_service) / 1e6

fy28_mid_m     <- fy28_b$mid_m[fy28_b$step_order == 4L]
exec_payouts_m <- 1.10 + 0.325
net_ath_sup_m  <- -(ath_recon_fy25$amount_m[ath_recon_fy25$step_id == 7L])
rem_recur_m    <- fy28_mid_m - net_ath_sup_m

topline_tbl <- tribble(
  ~section, ~item, ~amount_m, ~share_pct, ~growth_share_pct, ~source_citation,
  "FY26 E&G Budget", "Academic Colleges, Agencies & Student Support (incl. fringe)", fy26_acad_m,    fy26_acad_m / fy26_total_m, NA_real_, "ColOBS FY26",
  "FY26 E&G Budget", "Campus Operations, Facilities, IT & Central Admin (incl. fringe)", fy26_admin_m, fy26_admin_m / fy26_total_m, NA_real_, "ColOBS FY26 (Fmt 1600 Gen Admin = $47.50M / 5.4%)",
  "FY26 E&G Budget", "Institutional Financial Aid (E&G Discounting)",             fy26_aid_m,     fy26_aid_m / fy26_total_m, NA_real_, "ColOBS FY26",
  "FY26 E&G Budget", "Central Utilities, Insurance & Reserves",                   fy26_central_m, fy26_central_m / fy26_total_m, NA_real_, "ColOBS FY26",
  "FY26 E&G Budget", "Central E&G Capital Debt Service (XA)",                     fy26_debt_m,    fy26_debt_m / fy26_total_m, debt_grow_m / tot_grow_m, "ColOBS FY15 & FY26",
  "FY26 E&G Budget", "Athletics E&G Base Allocation (B2)",                        fy26_ath_m,     fy26_ath_m / fy26_total_m, ath_grow_m / tot_grow_m, "ColOBS FY15 & FY26",
  "FY28 Gap Scale",  "Combined Exec Transition Payouts (Pres $1.10M + Prov $0.33M, 1x)", exec_payouts_m, exec_payouts_m / fy28_mid_m, NA_real_, "Public Settlements (2026)",
  "FY28 Gap Scale",  "Net Institutional Athletics Operating Support (FY25 OSA)",   net_ath_sup_m,  net_ath_sup_m / fy28_mid_m, NA_real_, "Colorado OSA 2516F-B",
  "FY28 Gap Scale",  "Remaining Recurring FY28 Operating Gap",                    rem_recur_m,    rem_recur_m / fy28_mid_m, NA_real_, "Oct 7 Memo ($66M mid) less Net Ath"
)
write_csv(topline_tbl, file.path(proc_dir, "topline_takeaway_summary.csv"))

# ==============================================================================
# 6. PEER BENCHMARK SNAPSHOT (2023 IPEDS)
# ==============================================================================
message("--- Computing 6: 2023 IPEDS Peer Benchmarks ---")
peer_2023 <- ipeds |>
  filter(year == 2023L) |>
  mutate(
    short_name = case_when(
      unitid == 126818 ~ "CSU Fort Collins",
      unitid == 126614 ~ "CU Boulder",
      unitid == 126775 ~ "CO School of Mines",
      unitid == 209542 ~ "Oregon State",
      unitid == 236939 ~ "Washington State",
      unitid == 230728 ~ "Utah State",
      unitid == 155399 ~ "Kansas State",
      unitid == 153603 ~ "Iowa State"
    ),
    is_csu = (unitid == 126818),
    is_co  = unitid %in% c(126818, 126614, 126775),
    rev_total_m = rev_total_current / 1e6,
    debt_m = longterm_debt / 1e6
  ) |>
  select(
    unitid, short_name, inst_name_ref, is_csu, is_co, fte_best,
    tuition_share_rev, tuition_discount_rate, state_per_fte, debt_per_fte,
    noninst_to_inst_ratio, student_faculty_ratio, research_share_exp,
    inst_staff_count, noninst_staff_count, debt_m, rev_total_m
  ) |>
  arrange(desc(is_csu), desc(debt_per_fte))

write_csv(peer_2023, file.path(proc_dir, "peer_benchmarks_2023.csv"))
message("=== 03_analysis_metrics.R COMPLETE ===")
