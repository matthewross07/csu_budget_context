"""Verified figure ledger for the CSU budget page (v2).

Every number shown on the site comes from this file. Each entry records the
value, the source document, where in that document it appears, and what KIND
of statement it is:

  csu    - printed in a CSU document
  state  - printed in a State of Colorado document
  news   - reported by a news outlet (not in a primary document we hold)
  calc   - our arithmetic on figures of the kinds above
  infer  - our inference; the source does not state it directly

Dollar values are in millions unless the unit says otherwise.
Checked against the archived source PDFs/HTML on 2026-11-20.
"""

SOURCES = {
    "memo_oct7": dict(
        title="An early look at next year's budget (campus message, Oct. 7, 2026)",
        publisher="CSU, VP for University Operations and CFO",
        url="https://source.colostate.edu/an-early-look-at-next-years-budget/"),
    "forum_oct14": dict(
        title="FY 2027-28 Budget Kickoff, Version 1.0 (forum slides, Oct. 14, 2026)",
        publisher="CSU Division of University Operations",
        url="https://operations.colostate.edu/media/sites/109/2026/10/Fall-Budget-Forum-Slides-10.14.26.pdf"),
    "forum_may13": dict(
        title="FY27 Budget Update, V4 Incremental Budget (forum slides, May 13, 2026)",
        publisher="CSU Division of University Operations",
        url="https://operations.colostate.edu/media/sites/109/2026/05/Campus-V4-5-13-2026_a-1.pdf"),
    "forum_apr13": dict(
        title="FY27 Budget Update, Draft V4 (forum slides, April 13, 2026)",
        publisher="CSU Division of University Operations",
        url="https://operations.colostate.edu/media/sites/109/2026/04/Budget-Forum-4-13-2026.pdf"),
    "forum_jan15": dict(
        title="FY27 Budget Update, V3 (forum slides, Jan. 15, 2026)",
        publisher="CSU Division of University Operations",
        url="https://operations.colostate.edu/media/sites/109/2026/01/Budget-Update-V3-1-15-26-Campus-1.pdf"),
    "colobs_fy26": dict(
        title="Colleges and Divisions Operating Budget Summary, FY 2025-26",
        publisher="CSU Office of Budgets",
        url="https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY26_College_Division_OBS.pdf"),
    "colobs_fy15": dict(
        title="Colleges and Divisions Operating Budget Summary, FY 2014-15",
        publisher="CSU Office of Budgets",
        url="https://www.budgets.colostate.edu/Forms/CollegeDivisionOperating/FY15_College_Division_OBS.pdf"),
    "obs_fy27": dict(
        title="Operating Budget Summary, FY 2026-27",
        publisher="CSU Office of Budgets",
        url="https://www.budgets.colostate.edu/Forms/OperatingBudgetSummaries/FY27_Operating_Budget_Summary.pdf"),
    "bdb": dict(
        title="Budget Data Books, FY15-16 through FY26-27 (Formats 20 and 30, general campus)",
        publisher="CSU Office of Budgets, filed with the Colorado Department of Higher Education",
        url="https://www.budgets.colostate.edu/Forms/BudgetDataBooks/FINAL_BDB_FY26-27.pdf"),
    "factbook27": dict(
        title="CSU Fact Book FY 2026-27 (Oct. 22, 2026)",
        publisher="CSU Institutional Research, Planning and Effectiveness",
        url="https://www.ir.colostate.edu/wp-content/uploads/sites/21/2026/10/CSU_Factbook_FY27_2026-10-22.pdf"),
    "factbook26": dict(
        title="CSU Fact Book FY 2025-26",
        publisher="CSU Institutional Research, Planning and Effectiveness",
        url="https://www.ir.colostate.edu/wp-content/uploads/sites/21/2025/12/CSU_Factbook_FY26.pdf"),
    "osa_fy25": dict(
        title="CSU Department of Intercollegiate Athletics, NCAA agreed-upon procedures report, FY2025 (2516F-B)",
        publisher="Colorado Office of the State Auditor (CliftonLarsonAllen)",
        url="https://content.leg.colorado.gov/sites/default/files/documents/audits/2516F-B_csu_ncaa_aup_fy_25.pdf"),
    "bluebook": dict(
        title="2026 State Ballot Information Booklet (Blue Book)",
        publisher="Colorado Legislative Council Staff",
        url="https://content.leg.colorado.gov/sites/default/files/2026-bluebook-english-accessible.pdf"),
    "bls": dict(
        title="Consumer Price Index, All Urban Consumers (CUUR0000SA0)",
        publisher="U.S. Bureau of Labor Statistics",
        url="https://www.bls.gov/cpi/"),
    "chalk_a87": dict(
        title="Election results: Colorado voters approve Amendment 87, strike down Proposition 136 (updated Nov. 6, 2026)",
        publisher="Chalkbeat Colorado",
        url="https://www.chalkbeat.org/colorado/2026/11/03/colorado-amendment-87-tax-rate-change-2026-election-results/"),
    "chalk_suit": dict(
        title="Conservative group files lawsuit to stop Amendment 87 (Nov. 20, 2026)",
        publisher="Chalkbeat Colorado",
        url="https://www.chalkbeat.org/colorado/2026/11/20/advance-colorado-files-lawsuit-to-overturn-amendment-87-education-ballot-measure/"),
    "chalk_budget": dict(
        title="Gov. Jared Polis releases his final budget (Nov. 3, 2026)",
        publisher="Chalkbeat Colorado",
        url="https://www.chalkbeat.org/colorado/2026/11/03/governor-jared-polis-releases-his-final-budget-proposal/"),
    "denver7_budget": dict(
        title="Gov. Polis presents final budget proposal for 2027-28 ahead of projected $1.6 billion deficit (Nov. 2, 2026)",
        publisher="Denver7",
        url="https://www.denver7.com/news/politics/gov-polis-presents-final-budget-proposal-for-2027-28-ahead-of-projected-1-6-billion-deficit"),
    "collegian_results": dict(
        title="2026 Elections live results: Colorado ballot measures (Nov. 2026)",
        publisher="The Rocky Mountain Collegian",
        url="https://collegian.com/articles/news/2026/11/2026-elections-live-results-colorado-ballot-measures/"),
    "wiche": dict(
        title="Knocking at the College Door, 11th edition: projections of high school graduates (Dec. 2024)",
        publisher="Western Interstate Commission for Higher Education (WICHE)",
        url="https://www.wiche.edu/knocking/key-findings/graduates/"),
    "cosun_cliff": dict(
        title="The number of high school grads in Colorado is shrinking. Can colleges weather enrollment drops? (July 27, 2026)",
        publisher="The Colorado Sun",
        url="https://coloradosun.com/2026/07/27/colorado-college-enrollment-cliff-survival-strategies/"),
    "collegian_react": dict(
        title="Faculty, students react to Parsons' resignation (Nov. 2026)",
        publisher="The Rocky Mountain Collegian",
        url="https://collegian.com/articles/news/2026/11/category-news-students-faculty-react-to-parsons-resignation-express-concerns-around-transparency-accountability/"),
}

# id: (value, unit, plain description, source id, locator, kind)
F = {
    # ---- The FY28 projection ------------------------------------------------
    "gap_low": (61.3, "$M", "Projected FY28 gap, low end of CSU's range", "memo_oct7", "paragraph 'Where we are starting'", "csu"),
    "gap_high": (70.7, "$M", "Projected FY28 gap, high end of CSU's range", "memo_oct7", "paragraph 'Where we are starting'", "csu"),
    "enroll_gap": (25.0, "$M", "FY28 gap attributed by CSU to enrollment shifts ('about $25 million')", "memo_oct7", "paragraph 'What we know'", "csu"),
    # ---- FY27 (current year) -----------------------------------------------
    "fy27_new_expenses": (61.103, "$M", "FY27 new expenses before balancing actions (sum of slide lines 26-31)", "forum_may13", "slide 6, lines 26-31", "calc"),
    "fy27_net_new_resources": (6.831, "$M", "FY27 net new resources after financial aid", "forum_may13", "slide 5, line 24", "csu"),
    "fy27_gap": (54.272, "$M", "FY27 gap closed (new expenses minus net new resources); CSU's memo rounds to $54 million", "forum_may13", "slides 5-6", "calc"),
    "fy27_base_savings": (7.406, "$M", "FY27 university base savings", "forum_may13", "slide 6, line 32", "csu"),
    "fy27_campus_cuts": (28.754, "$M", "FY27 campus reduction target (permanent unit cuts)", "forum_may13", "slide 6, line 33", "csu"),
    "fy27_vacant": (3.000, "$M", "FY27 vacant position reductions", "forum_may13", "slide 6, line 34", "csu"),
    "fy27_permanent": (39.160, "$M", "FY27 permanent reductions (base savings + campus cuts + vacant positions)", "forum_may13", "slide 6, lines 32-34", "calc"),
    "fy27_onetime": (15.112, "$M", "FY27 one-time savings used to balance", "forum_may13", "slide 6, line 35", "csu"),
    "fy27_fte_cut": (160.58, "FTE", "Permanent positions reduced for FY27", "forum_may13", "slide 10, grand total", "csu"),
    "v4_enroll_ug": (-7.834, "$M", "FY27 tuition change from undergraduate enrollment", "forum_may13", "slide 5, line 5", "csu"),
    "v4_enroll_grad": (-4.846, "$M", "FY27 tuition change from graduate enrollment", "forum_may13", "slide 5, line 6", "csu"),
    "v4_enroll": (-12.680, "$M", "FY27 tuition change from enrollment, undergraduate plus graduate", "forum_may13", "slide 5, lines 5-6", "calc"),
    "v4_rates": (23.963, "$M", "FY27 revenue from tuition rate increases (resident 3.5%, nonresident 4%, graduate 3%, vet med, differential)", "forum_may13", "slide 5, lines 8-14", "calc"),
    "v4_state": (-0.858, "$M", "FY27 change in state funding (fee-for-service and specialty education)", "forum_may13", "slide 5, lines 16-17", "calc"),
    "v4_other_rev": (1.435, "$M", "FY27 other new resources (board-prioritized funding, overhead recovery)", "forum_may13", "slide 5, lines 18-19", "calc"),
    "v4_aid": (-5.029, "$M", "FY27 added financial aid, netted against new resources", "forum_may13", "slide 5, line 23", "csu"),
    "v4_comp": (33.665, "$M", "FY27 faculty/staff compensation (3% pool, classified raises, promotions, fringe)", "forum_may13", "slide 6, line 27", "csu"),
    "v4_mandatory": (8.678, "$M", "FY27 mandatory costs (bond payments, new facilities, insurance, utilities, library)", "forum_may13", "slide 6, line 29", "csu"),
    "v4_strategic": (8.826, "$M", "FY27 multi-year central investments in strategic initiatives", "forum_may13", "slide 6, line 26", "csu"),
    "v4_incentive": (8.120, "$M", "FY27 academic incentive funding (differential tuition, tuition sharing)", "forum_may13", "slide 6, line 28", "csu"),
    "v4_other_exp": (1.814, "$M", "FY27 quality enhancements plus board-prioritized mental health funding", "forum_may13", "slide 6, lines 30-31", "calc"),
    # ---- Size of the budget -------------------------------------------------
    "reducible": (551.0, "$M", "'Reducible' budget as CSU defined it for FY27 cuts", "forum_apr13", "slide 12", "csu"),
    "state_approp_fy26": (885.156, "$M", "FY26 'State Appropriated' budget (general campus plus vet med, Experiment Station, Extension, Forest Service)", "colobs_fy26", "grand total", "csu"),
    "la_budget": (57.810, "$M", "College of Liberal Arts general-fund (EG sub-fund) budget, FY26", "colobs_fy26", "line KA", "csu"),
    # ---- Fall 2026 census ---------------------------------------------------
    "ri_total": (27491, "students", "Fall 2026 Resident Instruction enrollment", "forum_oct14", "slide 5", "csu"),
    "ri_change": (-703, "students", "Change in RI enrollment, Fall 2025 to Fall 2026 (-2.5%)", "forum_oct14", "slide 5", "csu"),
    "nr_ug_change": (-685, "students", "Change in domestic nonresident undergraduates (-9.7%)", "forum_oct14", "slide 5", "csu"),
    "res_ug_change": (184, "students", "Change in resident undergraduates (+1.1%)", "forum_oct14", "slide 5", "csu"),
    "intl_ug_change": (-42, "students", "Change in international undergraduates (-6.7%)", "forum_oct14", "slide 5", "csu"),
    "intl_grad_change": (-113, "students", "Change in international graduate students (-13.9%)", "forum_oct14", "slide 5", "csu"),
    "gradrate_old": (51.1, "%", "Four-year graduation rate, prior cohort", "forum_oct14", "slide 6", "csu"),
    "gradrate_new": (55.1, "%", "Four-year graduation rate, latest cohort", "forum_oct14", "slide 6", "csu"),
    "nr_head_2024": (9997, "students", "Nonresident RI headcount, Fall 2024", "factbook27", "Table 3", "csu"),
    "nr_head_2026": (8422, "students", "Nonresident RI headcount, Fall 2026", "factbook27", "Table 3", "csu"),
    # ---- State funding to CSU ----------------------------------------------
    "state_total_fy27": (211.052, "$M", "FY27 state fee-for-service plus College Opportunity Fund, all state-funded Fort Collins units", "obs_fy27", "page 4 (revenue budget)", "calc"),
    "state_general_fy26": (110.090, "$M", "FY26 state support to the general campus budget (fee-for-service + COF stipend, actual)", "bdb", "FY26-27 book, Format 20 lines 14-15", "calc"),
    # ---- Ballot measures ----------------------------------------------------
    "a87_fy28": (1972.0, "$M", "Amendment 87 estimated new revenue, FY 2027-28", "bluebook", "p. 38", "state"),
    "nn_fy28": (521.0, "$M", "Proposition NN estimated revenue retained, FY 2027-28", "bluebook", "p. 46", "state"),
    "nn_gf_shift": (153.1, "$M", "Proposition NN: amount moved out of the general state budget in each of FY27 and FY28", "bluebook", "p. 47, Table 2", "state"),
    "p137_fy28": (175.0, "$M", "Proposition 137 estimated transfer to conservation programs, FY 2027-28", "bluebook", "p. 67", "state"),
    "p137_csfs": (36.5, "$M", "Proposition 137: maximum to the Colorado State Forest Service, FY 2027-28", "bluebook", "p. 68, Table 1", "state"),
    "a87_yes": (51.72, "%", "Amendment 87 yes vote (unofficial, as reported Nov. 20)", "chalk_suit", "second paragraph", "news"),
    "state_gap": (1.6, "$B", "Projected state budget shortfall for FY 2027-28 as reported with the governor's Nov. 2 proposal", "denver7_budget", "third paragraph", "news"),
    # ---- Things people point to --------------------------------------------
    "inst_support": (47.495, "$M", "General campus 'Institutional Support' spending, FY26 actual (central administration: executive, finance, HR, legal, etc.)", "bdb", "FY26-27 book, Format 20 line 6", "csu"),
    "inst_support_fte": (239.14, "FTE", "General campus 'Institutional Support' staff, FY26 actual", "bdb", "FY26-27 book, Format 20 line 6", "csu"),
    "debt_service": (31.864, "$M", "Debt service paid from the general-fund budget, FY26", "colobs_fy26", "line XA Debt Service", "csu"),
    "debt_service_fy15": (10.169, "$M", "Debt service paid from the general-fund budget, FY15", "colobs_fy15", "line XA Debt Service", "csu"),
    "athletics_eg": (17.151, "$M", "Athletics general-fund allocation, FY26", "colobs_fy26", "line B2", "csu"),
    "athletics_eg_fy15": (9.687, "$M", "Athletics general-fund allocation, FY15", "colobs_fy15", "line B2", "csu"),
    "ath_rev": (74.737, "$M", "Athletics total revenues, FY25", "osa_fy25", "p. 20 (PDF p. 24)", "state"),
    "ath_direct": (23.851, "$M", "Athletics direct institutional support, FY25", "osa_fy25", "p. 20", "state"),
    "ath_indirect": (2.147, "$M", "Athletics indirect institutional support, FY25", "osa_fy25", "p. 20", "state"),
    "ath_fees": (6.145, "$M", "Athletics student fee revenue, FY25", "osa_fy25", "p. 20", "state"),
    "ath_aid": (10.931, "$M", "Athletic student aid expense, FY25", "osa_fy25", "p. 20", "state"),
    "ath_debt": (206.960, "$M", "Athletics outstanding debt, June 30, 2025 (18.5% of university debt)", "osa_fy25", "Note 5, p. 22", "state"),
    "ath_debt_service": (10.942, "$M", "Athletics bond principal and interest paid, FY25", "osa_fy25", "Note 5, p. 22", "state"),
    "payout_parsons": (1.1, "$M", "Reported resignation payment to President Amy Parsons", "collegian_react", "citing The Coloradoan's records request", "news"),
    "payout_underwood": (0.325, "$M", "Reported settlement with former Provost Marion Underwood", "collegian_react", "paragraph on AAUP statement", "news"),
    "payout_norvell": (1.5, "$M", "Reported settlement with former football coach Jay Norvell", "collegian_react", "paragraph on AAUP statement", "news"),
    # ---- Staffing counts ----------------------------------------------------
    "cdhe_fte_fy15": (3506.41, "FTE", "General-fund faculty and staff FTE, FY15 (state filing)", "bdb", "FY15-16 book, Format 20 line 11", "csu"),
    "cdhe_fte_fy26": (3751.79, "FTE", "General-fund faculty and staff FTE, FY26 (state filing)", "bdb", "FY26-27 book, Format 20 line 11", "csu"),
    "fb_fac_fy15": (1167.3, "FTE", "General-fund faculty FTE, FY15 (Fact Book)", "factbook26", "pp. 107-110", "csu"),
    "fb_fac_fy25": (1319.1, "FTE", "General-fund faculty FTE, FY25 (Fact Book)", "factbook26", "pp. 107-110", "csu"),
    "fb_staff_fy15": (1429.4, "FTE", "General-fund administrative professional + state classified FTE, FY15 (Fact Book)", "factbook26", "pp. 111-112", "csu"),
    "fb_staff_fy25": (1709.3, "FTE", "General-fund administrative professional + state classified FTE, FY25 (Fact Book)", "factbook26", "pp. 111-112", "csu"),
    "ap_total": (4598.0, "FTE", "Administrative professional FTE, all funds, FY25", "factbook27", "Table 123", "csu"),
    "ap_eg": (1392.6, "FTE", "Administrative professional FTE paid from the general fund, FY25", "factbook27", "Table 123", "csu"),
    # ---- Cost per student ---------------------------------------------------
    "cost_per_fte_fy15": (18137, "$", "General-fund cost per student FTE, FY15 (state filing)", "bdb", "FY15-16 book, Format 30 line 16", "csu"),
    "cost_per_fte_fy26": (27815, "$", "General-fund cost per student FTE, FY26 (state filing)", "bdb", "FY26-27 book, Format 30 line 16", "csu"),
    "cpi_fy15": (236.677, "index", "CPI-U, average of July 2014-June 2015", "bls", "series CUUR0000SA0", "calc"),
    "cpi_fy25": (317.731, "index", "CPI-U, average of July 2024-June 2025", "bls", "series CUUR0000SA0", "calc"),
    "cpi_fy26": (327.668, "index", "CPI-U, average of July 2025-May 2026 (11 months available)", "bls", "series CUUR0000SA0", "calc"),
}

# ---- Inputs used only by the 2030 scenario page ---------------------------------
F.update({
    "t_nr_fy27": (254.058, "$M", "Nonresident tuition, FY27 estimate filed with the state (general campus)", "bdb", "FY26-27 book, Format 20 line 19, estimate column", "csu"),
    "t_res_fy27": (227.918, "$M", "Resident tuition paid by students, FY27 estimate filed with the state (general campus)", "bdb", "FY26-27 book, Format 20 lines 16 and 18, estimate column", "calc"),
    "comp_base_fy27": (551.198, "$M", "Salaries and benefits in the FY27 state-appropriated budget", "obs_fy27", "page 3, State Appropriated row (professional + support)", "calc"),
    "retention_old": (87.9, "%", "Second-year retention rate, prior cohort", "forum_oct14", "slide 6", "csu"),
    "retention_new": (86.4, "%", "Second-year retention rate, latest cohort", "forum_oct14", "slide 6", "csu"),
    "personnel_share": (60, "%", "Share of budget-cut proposals CSU required to come from personnel in FY27", "forum_jan15", "slide 9", "csu"),
    "wiche_us": (-13, "%", "Projected change in U.S. high school graduates, 2025 peak to 2041", "wiche", "key findings", "ext"),
    "wiche_co": (-14, "%", "Projected change in Colorado high school graduates, 2025 to 2041 (65,716 to 56,457)", "cosun_cliff", "citing WICHE projections", "news"),
    "wiche_ca": (-29, "%", "Projected change in California high school graduates, 2023 to 2041", "wiche", "press release, Dec. 11, 2024", "ext"),
    "wiche_il": (-32, "%", "Projected change in Illinois high school graduates, 2023 to 2041", "wiche", "press release, Dec. 11, 2024", "ext"),
})

# Scenario assumptions (author's choices, not facts). Years are FY28, FY29, FY30, FY31.
SCEN = {
    "common": dict(
        gap_fy28=66.0,          # midpoint of CSU's $61.3M-$70.7M range
        rate_res=0.03,          # resident tuition rate increase per year (governor's proposed cap)
        rate_nr=0.04,           # nonresident tuition rate increase per year (governor's proposed cap)
        state=0.01,             # state funding growth per year
        inflation=0.03,         # consumer price inflation per year
        mandatory=8.678,        # yearly growth in mandatory costs, held at the FY27 amount
        aid=5.029,              # yearly growth in financial aid, held at the FY27 amount
    ),
    "drift": dict(
        name="Year by year",
        onetime=[0.25, 0.25, 0.25, 0.25],      # share of each gap covered with one-time money
        raises=[0.01, 0.01, 0.01, 0.01],
        benefits=[10, 10, 10, 10],             # yearly growth in benefit costs, $M
        e_nr=[-0.06, -0.06, -0.06, -0.06],     # change in nonresident enrollment, falls 2027-2030
        e_res=[0.0, -0.01, -0.01, -0.01],      # change in resident enrollment
        newrev=[0, 0, 0, 0],                   # new revenue from new programs, $M per year added
        invest=[0, 0, 0, 0],                   # new spending on recruitment and retention, $M per year added
        restructure=0,                         # one-time transition cost, $M, paid from reserves
    ),
    "decide": dict(
        name="Decide early",
        onetime=[0.0, 0.0, 0.0, 0.0],
        raises=[0.01, 0.02, 0.03, 0.03],
        benefits=[8, 8, 8, 8],
        e_nr=[-0.06, -0.04, -0.01, 0.01],
        e_res=[0.0, 0.005, 0.01, 0.01],
        newrev=[0, 3, 5, 7],
        invest=[0, 6, 4, 2],
        restructure=35,
    ),
}

# Annual general-campus series from the Budget Data Books (actuals), dollars.
# fy: (nonresident tuition, resident UG student share, resident graduate tuition,
#      fee-for-service, COF stipend, total E&G expenditures,
#      resident student FTE, nonresident student FTE)
BDB = {
    2015: (142913115, 154675388, 17972113, 23575539, 36170860, 423744520, 17535.01, 5828.57),
    2016: (160173811, 163691115, 18371147, 28890341, 36328215, 456053643, 17849.50, 6569.60),
    2017: (187175711, 173105688, 18631359, 28603899, 36593504, 500411983, 17894.14, 7064.37),
    2018: (202220517, 179614724, 19366639, 28997098, 37154189, 551042759, 17883.87, 7464.21),
    2019: (220706786, 182229818, 19326062, 34021476, 40030947, 569477921, 17392.09, 7957.59),
    2020: (235785584, 181663680, 20880315, 38298242, 43643290, 603622796, 17145.54, 8181.02),
    2021: (217095940, 171310254, 21869390, 8863623, 17400486, 506610069, 16229.13, 7660.97),
    2022: (234268131, 174204724, 21429603, 50331130, 39436029, 574181005, 15719.30, 8193.13),
    2023: (246066248, 177110740, 22026101, 53538731, 43738576, 648118428, 15723.53, 8522.08),
    2024: (262921934, 184529004, 22405706, 59303044, 49018654, 670648525, 15837.80, 8674.74),
    2025: (279060799, 191692874, 23702658, 60826733, 49448526, 687896145, 16045.65, 8928.13),
    2026: (268887607, 206419534, 25072290, 58825209, 51264810, 700370470, 16664.18, 8242.37),
}

# Fall census, Resident Instruction students (Fact Book FY27, Table 3)
HEADCOUNT = {
    2019: (19644, 9220), 2020: (18974, 8861), 2021: (18423, 9531), 2022: (18200, 9756),
    2023: (18082, 9751), 2024: (18211, 9997), 2025: (18864, 9330), 2026: (19069, 8422),
}
