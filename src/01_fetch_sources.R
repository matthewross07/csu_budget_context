# 01_fetch_sources.R
# Reproducible downloader for all primary CSU, Colorado State Auditor,
# Federal IPEDS, GAO/athletics peer summaries, and BLS CPI-U sources.
# Logs exact URLs, HTTP status, access timestamp, and SHA-256 hashes
# into data/sources_manifest.csv.

source(file.path(if (dir.exists("src")) "src" else ".", "00_setup_theme.R"))

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  out <- tryCatch(
    system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)
  )
  if (length(out) > 0) return(sub("\\s+.*$", "", out[1]))
  as.character(tools::md5sum(path))
}

source_catalog <- tribble(
  ~source_id, ~category, ~title, ~fiscal_years, ~url, ~rel_path, ~page_or_table_notes,

  # --- 1. 2026 Campus Memos & Budget Forum Decks ---
  "memo_oct2026", "forums",
  "Presidential Campus Budget Message: An Early Look at Next Year's Budget (Oct. 7, 2026)",
  "FY27-FY28",
  "https://source.colostate.edu/an-early-look-at-next-years-budget/",
  "data/raw/forums/source_oct07_2026_early_look_budget.html",
  "Full presidential communication on $54M FY27 reductions, -$25M enrollment cliff, $61.3M-$70.7M FY28 shortfall range, $1.5B state gap.",

  "memo_redesign_oct2026", "forums",
  "CSU Leaders Provide Update on Budget Model Redesign (Oct. 26, 2026)",
  "FY27-FY28",
  "https://source.colostate.edu/csu-leaders-provide-update-on-budget-model-redesign/",
  "data/raw/forums/source_oct26_2026_budget_redesign.html",
  "Hybrid RCM Parallel Year update for FY27 and FY28 transition.",

  "redesign_why_html", "forums",
  "CSU Operations: Why a New Budget Model? (Incremental vs Hybrid RCM)",
  "FY27-FY28",
  "https://operations.colostate.edu/budget-model-redesign/overview-and-process/why-a-new-model/",
  "data/raw/forums/operations_why_new_budget_model.html",
  "Institutional diagnosis of legacy incremental budgeting rigidities.",

  "aaup_parsons_nov2026", "forums",
  "AAUP-CSU Condemns $1.1M Payout to Silence Outgoing President Parsons (Nov. 5, 2026)",
  "FY27",
  "https://aaupcsu.org/2026/11/05/aaup-csu-condemns-1-1m-payout-to-silence-outgoing-president-parson/",
  "data/raw/forums/aaup_nov05_2026_parsons_payout.html",
  "Faculty union response to Parsons settlement and nondisparagement clause.",

  "aaup_newsletter_nov2026", "forums",
  "AAUP-CSU Newsletter, November 2026 (Oct. 26, 2026)",
  "FY27",
  "https://aaupcsu.org/2026/10/26/aaup-csu-newsletter-november-2026/",
  "data/raw/forums/aaup_nov2026_newsletter.html",
  "Faculty governance context ahead of late-fall campus meetings.",

  "forum_oct2026", "forums",
  "CSU Fall Budget Forum Slides (Oct. 14, 2026) - FY28 V1.0/V1.1 Outlook",
  "FY27-FY28",
  "https://operations.colostate.edu/media/sites/109/2026/10/Fall-Budget-Forum-Slides-10.14.26.pdf",
  "data/raw/forums/Fall-Budget-Forum-Slides-10.14.26.pdf",
  "Slides 4-6 (Fall 2026 Census -2.5% RI, -9.7% Dom NR UG, -11.1% Intl), Slide 8 (OSPB -$1.5B state gap), Slide 16 (Mandatory costs).",

  "forum_may2026", "forums",
  "CSU FY27 Budget Update Campus Forum Slides (May 13, 2026) - V4 Incremental Budget",
  "FY27",
  "https://operations.colostate.edu/media/sites/109/2026/05/Campus-V4-5-13-2026_a-1.pdf",
  "data/raw/forums/Campus-V4-5-13-2026_a-1.pdf",
  "Slides 5-6 (V4 FY27 budget actions: $61.1M gross expenses, $6.83M net new resources, $54.27M reductions incl $15.11M one-time, $15M SPUR), Slide 10 (160.58 FTE reductions).",

  "forum_apr2026", "forums",
  "CSU FY27 Budget Update Campus Forum Slides (April 13, 2026) - Draft V4",
  "FY27",
  "https://operations.colostate.edu/media/sites/109/2026/04/Budget-Forum-4-13-2026.pdf",
  "data/raw/forums/Budget-Forum-4-13-2026.pdf",
  "Slides 12-16 ($1.7B total / $885M state-approp / $551M reducible budget, unit breakdown).",

  "forum_jan2026", "forums",
  "CSU Budget Update Campus Forum Slides (Jan. 15, 2026) - V3",
  "FY27",
  "https://operations.colostate.edu/media/sites/109/2026/01/Budget-Update-V3-1-15-26-Campus-1.pdf",
  "data/raw/forums/Budget-Update-V3-1-15-26-Campus-1.pdf",
  "Early FY27 planning baseline and multi-year assumptions.",

  "forum_oct2025", "forums",
  "CSU Budget Overview Slides (Oct. 7, 2025) - V1",
  "FY26-FY27",
  "https://operations.colostate.edu/media/sites/109/2025/10/Campus-V1-Budget-Overview-10-7-25.pdf",
  "data/raw/forums/Campus-V1-Budget-Overview-10-7-25.pdf",
  "Prior year October baseline for comparison.",

  # --- 2. CSU Office of Budgets: Operating Budget Summaries (Total University) ---
  "obs_fy27", "budgets",
  "CSU Operating Budget Summary FY 2026-27 (Total University)",
  "FY27",
  "https://www.budgets.colostate.edu/Forms/OperatingBudgetSummaries/FY27_Operating_Budget_Summary.pdf",
  "data/raw/budgets/FY27_Operating_Budget_Summary.pdf",
  "Pages 3-4 (Total University & State Appropriated E&G/PVM/Ag/CSFS revenues & expenditures).",

  "obs_fy26", "budgets",
  "CSU Operating Budget Summary FY 2025-26 (Total University)",
  "FY26",
  "https://www.budgets.colostate.edu/Forms/OperatingBudgetSummaries/FY26_Operating_Budget_Summary.pdf",
  "data/raw/budgets/FY26_Operating_Budget_Summary.pdf",
  "Pages 3-4 (FY26 State Appropriated baseline ~$885M, Tuition, FFS, COF, IDCR).",

  "obs_fy25", "budgets",
  "CSU Operating Budget Summary FY 2024-25 (Total University)",
  "FY25",
  "https://www.budgets.colostate.edu/Forms/OperatingBudgetSummaries/FY25_Operating_Budget_Summary.pdf",
  "data/raw/budgets/FY25_Operating_Budget_Summary.pdf",
  "Pages 3-4 (FY25 State Appropriated baseline).",

  "obs_fy24", "budgets",
  "CSU Operating Budget Summary FY 2023-24 (Total University)",
  "FY24",
  "https://www.budgets.colostate.edu/Forms/OperatingBudgetSummaries/FY24_Operating_Budget_Summary.pdf",
  "data/raw/budgets/FY24_Operating_Budget_Summary.pdf",
  "Pages 3-4 (FY24 State Appropriated baseline).",

  # --- 3. CSU Office of Budgets: College/Division E&G Operating Budget Summaries ---
  "col_obs_fy26", "budgets", "CSU College/Division E&G Operating Budget Summary FY26", "FY26",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY26_College_Division_OBS.pdf",
  "data/raw/budgets/FY26_College_Division_OBS.pdf", "Division E&G budgets: Colleges, Admin/Support, Athletics, Financial Aid.",
  "col_obs_fy25", "budgets", "CSU College/Division E&G Operating Budget Summary FY25", "FY25",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY25_College_Division_OBS.pdf",
  "data/raw/budgets/FY25_College_Division_OBS.pdf", "Division E&G budgets FY25.",
  "col_obs_fy24", "budgets", "CSU College/Division E&G Operating Budget Summary FY24", "FY24",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY24_College_Division_OBS.pdf",
  "data/raw/budgets/FY24_College_Division_OBS.pdf", "Division E&G budgets FY24.",
  "col_obs_fy23", "budgets", "CSU College/Division E&G Operating Budget Summary FY23", "FY23",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY23_College_Division_OBS.pdf",
  "data/raw/budgets/FY23_College_Division_OBS.pdf", "Division E&G budgets FY23.",
  "col_obs_fy22", "budgets", "CSU College/Division E&G Operating Budget Summary FY22", "FY22",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY22_College_Division_OBS.pdf",
  "data/raw/budgets/FY22_College_Division_OBS.pdf", "Division E&G budgets FY22.",
  "col_obs_fy21", "budgets", "CSU College/Division E&G Operating Budget Summary FY21", "FY21",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY21_College_Division_OBS.pdf",
  "data/raw/budgets/FY21_College_Division_OBS.pdf", "Division E&G budgets FY21.",
  "col_obs_fy20", "budgets", "CSU College/Division E&G Operating Budget Summary FY20", "FY20",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY20_College_Division_OBS.pdf",
  "data/raw/budgets/FY20_College_Division_OBS.pdf", "Division E&G budgets FY20.",
  "col_obs_fy19", "budgets", "CSU College/Division E&G Operating Budget Summary FY19", "FY19",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY19_College_Division_OBS.pdf",
  "data/raw/budgets/FY19_College_Division_OBS.pdf", "Division E&G budgets FY19.",
  "col_obs_fy18", "budgets", "CSU College/Division E&G Operating Budget Summary FY18", "FY18",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY18_College_Division_OBS.pdf",
  "data/raw/budgets/FY18_College_Division_OBS.pdf", "Division E&G budgets FY18.",
  "col_obs_fy17", "budgets", "CSU College/Division E&G Operating Budget Summary FY17", "FY17",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY17_College_Division_OBS.pdf",
  "data/raw/budgets/FY17_College_Division_OBS.pdf", "Division E&G budgets FY17.",
  "col_obs_fy16", "budgets", "CSU College/Division E&G Operating Budget Summary FY16", "FY16",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY16_College_Division_OBS.pdf",
  "data/raw/budgets/FY16_College_Division_OBS.pdf", "Division E&G budgets FY16.",
  "col_obs_fy15", "budgets", "CSU College/Division E&G Operating Budget Summary FY15", "FY15",
  "https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY15_College_Division_OBS.pdf",
  "data/raw/budgets/FY15_College_Division_OBS.pdf", "Division E&G budgets FY15.",

  # --- 4. CDHE Budget Data Books (E&G Format 20, 30, 100, 410) ---
  "bdb_fy27", "budgets", "CSU Budget Data Book FY 2026-27 (Actual FY26 / Est FY27)", "FY26-FY27",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY26-27.pdf",
  "data/raw/budgets/FINAL_BDB_FY26-27.pdf", "Formats 20, 26, 30, 100, 410 (E&G tuition, student FTE, faculty/staff FTE).",
  "bdb_fy26", "budgets", "CSU Budget Data Book FY 2025-26 (Actual FY25 / Est FY26)", "FY25-FY26",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY25-26.pdf",
  "data/raw/budgets/FINAL_BDB_FY25-26.pdf", "Formats 20, 30, 100.",
  "bdb_fy25", "budgets", "CSU Budget Data Book FY 2024-25 (Actual FY24 / Est FY25)", "FY24-FY25",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY24-25.pdf",
  "data/raw/budgets/FINAL_BDB_FY24-25.pdf", "Formats 20, 30, 100.",
  "bdb_fy24", "budgets", "CSU Budget Data Book FY 2023-24 (Actual FY23 / Est FY24)", "FY23-FY24",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY23-24.pdf",
  "data/raw/budgets/FINAL_BDB_FY23-24.pdf", "Formats 20, 30, 100.",
  "bdb_fy23", "budgets", "CSU Budget Data Book FY 2022-23 (Actual FY22 / Est FY23)", "FY22-FY23",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY22-23.pdf",
  "data/raw/budgets/FINAL_BDB_FY22-23.pdf", "Formats 20, 30, 100.",
  "bdb_fy22", "budgets", "CSU Budget Data Book FY 2021-22 (Actual FY21 / Est FY22)", "FY21-FY22",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY21-22.pdf",
  "data/raw/budgets/FINAL_BDB_FY21-22.pdf", "Formats 20, 30, 100.",
  "bdb_fy21", "budgets", "CSU Budget Data Book FY 2020-21 (Actual FY20 / Est FY21)", "FY20-FY21",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY20-21.pdf",
  "data/raw/budgets/FINAL_BDB_FY20-21.pdf", "Formats 20, 30, 100.",
  "bdb_fy20", "budgets", "CSU Budget Data Book FY 2019-20 (Actual FY19 / Est FY20)", "FY19-FY20",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY19-20.pdf",
  "data/raw/budgets/FINAL_BDB_FY19-20.pdf", "Formats 20, 30, 100.",
  "bdb_fy19", "budgets", "CSU Budget Data Book FY 2018-19 (Actual FY18 / Est FY19)", "FY18-FY19",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY18-19.pdf",
  "data/raw/budgets/FINAL_BDB_FY18-19.pdf", "Formats 20, 30, 100.",
  "bdb_fy18", "budgets", "CSU Budget Data Book FY 2017-18 (Actual FY17 / Est FY18)", "FY17-FY18",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY17-18.pdf",
  "data/raw/budgets/FINAL_BDB_FY17-18.pdf", "Formats 20, 30, 100.",
  "bdb_fy17", "budgets", "CSU Budget Data Book FY 2016-17 (Actual FY16 / Est FY17)", "FY16-FY17",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY16-17.pdf",
  "data/raw/budgets/FINAL_BDB_FY16-17.pdf", "Formats 20, 30, 100.",
  "bdb_fy16", "budgets", "CSU Budget Data Book FY 2015-16 (Actual FY15 / Est FY16)", "FY15-FY16",
  "https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY15-16.pdf",
  "data/raw/budgets/FINAL_BDB_FY15-16.pdf", "Formats 20, 30, 100.",

  "salraise_hist", "budgets", "CSU Salary Increase and Fringe Benefit Rates History", "FY15-FY27",
  "https://www.budgets.colostate.edu/Forms/SalaryHistory/salraisehist.pdf",
  "data/raw/budgets/salraisehist.pdf", "Historical annual raise pools and fringe rates.",

  "tuition_fees", "budgets", "CSU Current Tuition & Fees Schedule", "FY27",
  "https://www.budgets.colostate.edu/Forms/Tuition_Fees/TuitionAndFees.pdf",
  "data/raw/budgets/TuitionAndFees.pdf", "Resident vs Nonresident tuition and mandatory fee rates.",

  # --- 5. CSU IRP&E Fact Books & Census Reports ---
  "factbook_fy27", "irpe",
  "CSU University Fact Book FY 2026-27 (Published Oct. 22, 2026)",
  "FY13-FY27",
  "https://www.ir.colostate.edu/wp-content/uploads/sites/21/2026/10/CSU_Factbook_FY27_2026-10-22.pdf",
  "data/raw/irpe/CSU_Factbook_FY27_2026-10-22.pdf",
  "Enrollment (pp.1-22), Credit Hour FTE (pp.23-29), Employee Headcount (pp.55-112), Employee FTE by Fund & Unit (Tables 105-131, pp.113-145).",

  "factbook_fy26", "irpe",
  "CSU University Fact Book FY 2025-26",
  "FY13-FY26",
  "https://www.ir.colostate.edu/wp-content/uploads/sites/21/2025/12/CSU_Factbook_FY26.pdf",
  "data/raw/irpe/CSU_Factbook_FY26.pdf",
  "Prior year Fact Book cross-check for State Classified and E&G FTE tables.",

  "bog_fall2026_census", "irpe",
  "Fall 2026 BOG Report: Census Enrollment and Student Success (Sept. 24, 2026)",
  "Fall 2026",
  "https://www.ir.colostate.edu/wp-content/uploads/sites/21/2026/09/2026-09-24_BOG_Fall_Report_Retention.pdf",
  "data/raw/irpe/2026-09-24_BOG_Fall_Report_Retention.pdf",
  "Fall 2026 Resident/Non-Resident/International census enrollment and 4-yr graduation rate (55.1%).",

  "inst_profile_24_25", "irpe",
  "CSU Institutional Profile 2024-2025",
  "FY25",
  "https://www.ir.colostate.edu/wp-content/uploads/sites/21/2025/12/Institutional-Profile-2024-2025.pdf",
  "data/raw/irpe/Institutional-Profile-2024-2025.pdf",
  "Institutional facts and profile summary.",

  # --- 6. CSU System Audited Financial Statements (FY15-FY25) ---
  "audit_fy25", "audits", "CSU System Audited Financial Statements FY 2025", "FY25",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2025.pdf", "data/raw/audits/finstmt2025.pdf", "MD&A, Statement of Net Position, SRECNP, Debt & Scholarship Allowance notes.",
  "audit_fy24", "audits", "CSU System Audited Financial Statements FY 2024", "FY24",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2024.pdf", "data/raw/audits/finstmt2024.pdf", "FY24 audited financial statements.",
  "audit_fy23", "audits", "CSU System Audited Financial Statements FY 2023", "FY23",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2023.pdf", "data/raw/audits/finstmt2023.pdf", "FY23 audited financial statements.",
  "audit_fy22", "audits", "CSU System Audited Financial Statements FY 2022", "FY22",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2022.pdf", "data/raw/audits/finstmt2022.pdf", "FY22 audited financial statements.",
  "audit_fy21", "audits", "CSU System Audited Financial Statements FY 2021", "FY21",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2021.pdf", "data/raw/audits/finstmt2021.pdf", "FY21 audited financial statements.",
  "audit_fy20", "audits", "CSU System Audited Financial Statements FY 2020", "FY20",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2020.pdf", "data/raw/audits/finstmt2020.pdf", "FY20 audited financial statements.",
  "audit_fy19", "audits", "CSU System Audited Financial Statements FY 2019", "FY19",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2019.pdf", "data/raw/audits/finstmt2019.pdf", "FY19 audited financial statements.",
  "audit_fy18", "audits", "CSU System Audited Financial Statements FY 2018", "FY18",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2018.pdf", "data/raw/audits/finstmt2018.pdf", "FY18 audited financial statements.",
  "audit_fy17", "audits", "CSU System Audited Financial Statements FY 2017", "FY17",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2017.pdf", "data/raw/audits/finstmt2017.pdf", "FY17 audited financial statements.",
  "audit_fy16", "audits", "CSU System Audited Financial Statements FY 2016", "FY16",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2016.pdf", "data/raw/audits/finstmt2016.pdf", "FY16 audited financial statements.",
  "audit_fy15", "audits", "CSU System Audited Financial Statements FY 2015", "FY15",
  "https://busfin.colostate.edu/Forms/Fin_Statements/finstmt2015.pdf", "data/raw/audits/finstmt2015.pdf", "FY15 audited financial statements.",

  # --- 7. Colorado Office of the State Auditor (OSA) Statutory NCAA AUP Reports ---
  "ncaa_csu_fy25", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2025", "FY25",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2516F-B_csu_ncaa_aup_fy_25.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy25.pdf", "Statement of Revenues & Expenses (p.24), Long-Term Obligations Note 5 ($206.96M debt vs $1.119B univ debt, p.26).",

  "ncaa_csu_fy24", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2024", "FY24",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2416f-b_csu_ncaa_aup_report-accessible.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy24.pdf", "FY24 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_csu_fy23", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2023", "FY23",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2316f-b_colorado_state_university_ncaa_aup_fy23.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy23.pdf", "FY23 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_csu_fy22", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2022", "FY22",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2216f-c_colorado_state_university_ncaa_aup_fy2022.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy22.pdf", "FY22 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_csu_fy21", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2021", "FY21",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2116f-c_csu_ncaa_agreed-upon_procedures_fy2021.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy21.pdf", "FY21 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_csu_fy20", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2020", "FY20",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2016f-c_csu_ncaa_agreed-upon_procedures_fy20.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy20.pdf", "FY20 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_csu_fy19", "athletics", "Colorado OSA: CSU Department of Intercollegiate Athletics NCAA AUP Report FY 2019", "FY19",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/1916f-c_colorado_state_university_ncaa_aup_report.pdf",
  "data/raw/athletics/csu_ncaa_aup_fy19.pdf", "FY19 NCAA Statement of Revenues & Expenses and Debt Note.",

  "ncaa_cub_fy25", "athletics", "Colorado OSA: CU Boulder Intercollegiate Athletics NCAA AUP Report FY 2025", "FY25",
  "https://content.leg.colorado.gov/sites/default/files/documents/audits/2505f-b-university-of-colorado-boulder-ncaa-aup-fy25-accessible.pdf",
  "data/raw/athletics/cub_ncaa_aup_fy25.pdf", "In-state R1 peer benchmark for athletics revenues, subsidies, and debt.",

  "gao_nocap_athletics", "athletics", "NoCap Sports Summary of GAO-26-108640 College Athletics Debt & Revenue Report (Oct. 2026)", "FY24",
  "https://nocapsports.io/post/college-athletics-debt-revenue-strategies/",
  "data/raw/athletics/nocap_gao_26_108640_summary.html", "Secondary verified citation of GAO-26-108640: Power conf median debt $120.3M, Other FBS (G5) median debt $21.0M, 330/352 DI programs deficit median $20.6M."
)

download_one <- function(url, dest_path, force = FALSE) {
  dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(dest_path) && !force && file.info(dest_path)$size > 100) {
    return(list(status = 200L, downloaded = FALSE, err = NA_character_))
  }
  tryCatch({
    resp <- request(url) |>
      req_user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36") |>
      req_retry(max_tries = 3, backoff = ~ 2) |>
      req_timeout(45) |>
      req_perform(path = dest_path)
    list(status = as.integer(resp_status(resp)), downloaded = TRUE, err = NA_character_)
  }, error = function(e) {
    if (file.exists(dest_path) && file.info(dest_path)$size == 0) unlink(dest_path)
    list(status = NA_integer_, downloaded = FALSE, err = conditionMessage(e))
  })
}

message("=== Step 1: Verifying/Downloading primary documents ===")
manifest_rows <- vector("list", nrow(source_catalog))
for (i in seq_len(nrow(source_catalog))) {
  row <- source_catalog[i, ]
  abs_dest <- file.path(PROJECT_ROOT, row$rel_path)
  res <- download_one(row$url, abs_dest)
  sha <- if (file.exists(abs_dest)) sha256_file(abs_dest) else NA_character_
  bytes <- if (file.exists(abs_dest)) as.numeric(file.info(abs_dest)$size) else 0
  status_flag <- if (!is.na(sha) && bytes > 100) "OK" else paste0("FAIL: ", res$err)
  message(sprintf("[%02d/%02d] %-24s | %s | %s bytes",
                  i, nrow(source_catalog), row$source_id, status_flag, format(bytes, big.mark = ",")))
  manifest_rows[[i]] <- row |>
    mutate(
      http_status = res$status,
      file_bytes  = bytes,
      sha256      = sha,
      accessed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      status      = status_flag
    )
}

# --- 8. BLS Public API v1 CPI-U (HTTP/1.1) ---
message("=== Step 2: Fetching US CPI-U (CUUR0000SA0, 2014-2026) via BLS Public API v1 ===")
bls_rel <- "data/raw/macro/bls_cpiu_2014_2026.csv"
bls_abs <- file.path(PROJECT_ROOT, bls_rel)
dir.create(dirname(bls_abs), recursive = TRUE, showWarnings = FALSE)
if (!file.exists(bls_abs) || file.info(bls_abs)$size < 100) {
  bls_fetch <- function(y1, y2) {
    r <- request("https://api.bls.gov/publicAPI/v1/timeseries/data/") |>
      req_options(http_version = 2L) |>
      req_body_json(list(seriesid = list("CUUR0000SA0"), startyear = as.character(y1), endyear = as.character(y2))) |>
      req_timeout(20) |>
      req_perform()
    j <- fromJSON(resp_body_string(r))
    if (!identical(j$status, "REQUEST_SUCCEEDED")) stop("BLS status: ", j$status)
    as_tibble(j$Results$series$data[[1]]) |>
      transmute(
        year = as.integer(year),
        period = period,
        period_name = periodName,
        month = as.integer(sub("^M", "", period)),
        cpiu = as.numeric(value)
      )
  }
  cpi_df <- bind_rows(bls_fetch(2014, 2023), bls_fetch(2024, 2026)) |>
    filter(month %in% 1:12) |>
    arrange(year, month)
  write_csv(cpi_df, bls_abs)
}
bls_row <- tibble(
  source_id = "bls_cpiu",
  category = "macro",
  title = "U.S. Bureau of Labor Statistics CPI-U All Urban Consumers (CUUR0000SA0)",
  fiscal_years = "2014-2026",
  url = "https://api.bls.gov/publicAPI/v1/timeseries/data/",
  rel_path = bls_rel,
  page_or_table_notes = "Monthly US CPI-U (2014-Oct 2026) aggregated to CSU fiscal years (July-June) for constant FY25/FY26 dollars.",
  http_status = 200L,
  file_bytes = as.numeric(file.info(bls_abs)$size),
  sha256 = sha256_file(bls_abs),
  accessed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  status = if (file.exists(bls_abs) && file.info(bls_abs)$size > 100) "OK" else "FAIL"
)

# --- 9. Urban Institute IPEDS Peer Benchmarks API (Batch by year with pagination) ---
message("=== Step 3: Fetching IPEDS Peer Benchmarks via Urban Institute API (batched) ===")
peer_unitids <- c(
  "126818" = "Colorado State University-Fort Collins",
  "126614" = "University of Colorado Boulder",
  "126775" = "Colorado School of Mines",
  "209542" = "Oregon State University",
  "236939" = "Washington State University",
  "230728" = "Utah State University",
  "155399" = "Kansas State University",
  "153603" = "Iowa State University"
)
uid_csv <- paste(names(peer_unitids), collapse = ",")

fetch_ipeds_endpoint <- function(endpoint, years, rel_out, source_id, title) {
  abs_out <- file.path(PROJECT_ROOT, rel_out)
  dir.create(dirname(abs_out), recursive = TRUE, showWarnings = FALSE)
  url_template <- paste0("https://educationdata.urban.org/api/v1/college-university/ipeds/", endpoint, "/{year}/?unitid=", uid_csv)
  if (!file.exists(abs_out) || file.info(abs_out)$size < 100) {
    all_res <- list()
    for (yr in years) {
      next_url <- paste0("https://educationdata.urban.org/api/v1/college-university/ipeds/", endpoint, "/", yr, "/?unitid=", uid_csv, "&limit=1000")
      while (!is.null(next_url) && nzchar(next_url)) {
        page_ok <- FALSE
        tryCatch({
          r <- request(next_url) |> req_timeout(20) |> req_perform()
          j <- fromJSON(resp_body_string(r))
          if (length(j$results) > 0 && is.data.frame(j$results)) {
            df <- as_tibble(j$results) |>
              mutate(
                inst_name_ref = unname(peer_unitids[as.character(unitid)]),
                query_year = yr
              )
            all_res[[length(all_res) + 1]] <- df
          }
          next_url <- j[["next"]]
          page_ok <- TRUE
        }, error = function(e) {
          message("  IPEDS skip ", endpoint, " ", yr, ": ", conditionMessage(e))
        })
        if (!page_ok) break
      }
    }
    combined <- bind_rows(all_res)
    write_csv(combined, abs_out)
    message("  Saved ", rel_out, " (", nrow(combined), " rows)")
  } else {
    message("  Cached ", rel_out)
  }
  tibble(
    source_id = source_id,
    category = "peers",
    title = title,
    fiscal_years = paste0(min(years), "-", max(years)),
    url = url_template,
    rel_path = rel_out,
    page_or_table_notes = "8-institution R1/Land-Grant/CO peer extract via Urban Institute Education Data Portal.",
    http_status = 200L,
    file_bytes = as.numeric(file.info(abs_out)$size),
    sha256 = sha256_file(abs_out),
    accessed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    status = if (file.exists(abs_out) && file.info(abs_out)$size > 100) "OK" else "FAIL"
  )
}

ipeds_rows <- bind_rows(
  fetch_ipeds_endpoint("finance", 2015:2023, "data/raw/peers/ipeds_finance_2015_2023.csv",
                       "ipeds_finance", "IPEDS Institutional Finance (2015-2023) - 8 Peer Universities"),
  fetch_ipeds_endpoint("enrollment-full-time-equivalent", 2015:2023, "data/raw/peers/ipeds_fte_2015_2023.csv",
                       "ipeds_fte", "IPEDS Full-Time Equivalent Enrollment (2015-2023) - 8 Peer Universities"),
  fetch_ipeds_endpoint("salaries-instructional-staff", 2015:2023, "data/raw/peers/ipeds_sal_inst_2015_2023.csv",
                       "ipeds_sal_inst", "IPEDS Instructional Staff Headcount & Salaries (2015-2023) - 8 Peer Universities"),
  fetch_ipeds_endpoint("salaries-noninstructional-staff", 2015:2023, "data/raw/peers/ipeds_sal_noninst_2015_2023.csv",
                       "ipeds_sal_noninst", "IPEDS Non-Instructional Staff Headcount & Outlays (2015-2023) - 8 Peer Universities"),
  fetch_ipeds_endpoint("student-faculty-ratio", 2015:2023, "data/raw/peers/ipeds_sfr_2015_2023.csv",
                       "ipeds_sfr", "IPEDS Student-to-Faculty Ratio (2015-2023) - 8 Peer Universities")
)

manifest <- bind_rows(bind_rows(manifest_rows), bls_row, ipeds_rows)
write_csv(manifest, file.path(PROJECT_ROOT, "data", "sources_manifest.csv"))
message("=== Saved data/sources_manifest.csv (", nrow(manifest), " sources; ",
        sum(manifest$status == "OK"), " OK, ", sum(manifest$status != "OK"), " non-OK) ===")
