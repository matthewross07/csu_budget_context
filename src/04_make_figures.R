# 04_make_figures.R
# Generates all 6 publication-grade ggplot2 figures (300-DPI PNG & vector SVG)
# into outputs/figures/.

source(file.path(if (dir.exists("src")) "src" else ".", "00_setup_theme.R"))

proc_dir <- file.path(PROJECT_ROOT, "data", "processed")

fy28_bridge <- read_csv(file.path(proc_dir, "fy28_shortfall_bridge.csv"), show_col_types = FALSE)
blame_pie   <- read_csv(file.path(proc_dir, "structural_blame_pie.csv"), show_col_types = FALSE)
wf_cohorts  <- read_csv(file.path(proc_dir, "workforce_cohorts_fy15_fy25.csv"), show_col_types = FALSE)
ap_summary  <- read_csv(file.path(proc_dir, "cemml_ap_unit_summary_fy25.csv"), show_col_types = FALSE)
bdb_real    <- read_csv(file.path(proc_dir, "bdb_real_fy17_fy27.csv"), show_col_types = FALSE)
real_aud    <- read_csv(file.path(proc_dir, "real_audits_fy15_fy25.csv"), show_col_types = FALSE)
ath_recon   <- read_csv(file.path(proc_dir, "athletics_gross_to_net_fy25.csv"), show_col_types = FALSE)
ath_peers   <- read_csv(file.path(proc_dir, "athletics_debt_peers.csv"), show_col_types = FALSE)
div_shares  <- read_csv(file.path(proc_dir, "division_budget_shares_fy17_fy26.csv"), show_col_types = FALSE)
cpi_fy      <- read_csv(file.path(proc_dir, "macro_cpiu_fy.csv"), show_col_types = FALSE)
peer_2023   <- read_csv(file.path(proc_dir, "peer_benchmarks_2023.csv"), show_col_types = FALSE)

# ==============================================================================
# FIGURE 1: LEDGER A — FY28 OPERATING SHORTFALL BRIDGE + SEVERANCE SCALE
# ==============================================================================
message("--- Building Figure 1: FY28 Shortfall Bridge ---")

wf_df <- tibble(
  id = 1:5,
  label = c(
    "Enrollment &\nTuition Mix Drop",
    "Expiring FY27\nOne-Time Funds",
    "Mandatory Inflation,\nComp & State Freeze",
    "Projected FY28\nShortfall (Midpoint)",
    "Context: Presidential\nTransition Settlement"
  ),
  ymin = c(0, 25.00, 40.11, 0, 0),
  ymax = c(25.00, 40.11, 66.00, 66.00, 1.10),
  fill_grp = c("Core Cliff Driver", "Core Cliff Driver", "Scenario Range", "Total FY28 Gap", "One-Time Severance"),
  txt_lbl = c(
    "-$25.0M\n(~38% of gap)",
    "-$15.1M\n(~23% of gap)",
    "-$25.9M\n(-$21.2M to -$30.6M)",
    "-$66.0M\n($61.3M-$70.7M)",
    "$1.1M\n(1.7% of 1-yr gap)"
  )
)

fig1 <- ggplot(wf_df, aes(x = id)) +
  annotate("segment", x = 1.34, xend = 1.66, y = 25.00, yend = 25.00,
           linetype = "dashed", color = csu_colors$gray_mid, linewidth = 0.5) +
  annotate("segment", x = 2.34, xend = 2.66, y = 40.11, yend = 40.11,
           linetype = "dashed", color = csu_colors$gray_mid, linewidth = 0.5) +
  annotate("segment", x = 3.34, xend = 3.66, y = 66.00, yend = 66.00,
           linetype = "dashed", color = csu_colors$gray_mid, linewidth = 0.5) +
  geom_vline(xintercept = 4.5, linetype = "dotted", color = csu_colors$slate, linewidth = 0.6) +
  geom_rect(aes(xmin = id - 0.34, xmax = id + 0.34, ymin = ymin, ymax = ymax, fill = fill_grp),
            color = NA, alpha = 0.92) +
  geom_errorbar(
    data = tibble(id = c(3, 4), lo = c(61.30, 61.30), hi = c(70.70, 70.70)),
    aes(x = id, ymin = lo, ymax = hi),
    inherit.aes = FALSE, width = 0.16, linewidth = 0.85, color = csu_colors$slate
  ) +
  geom_text(
    aes(y = ifelse(id %in% c(3, 4), 70.70, ymax) + 2.2, label = txt_lbl),
    vjust = 0, size = 3.2, fontface = "bold", color = csu_colors$slate, lineheight = 1.15
  ) +
  annotate("text", x = 5, y = 19,
           label = "Scale Note:\nOne-time transition\nsettlement ($1.1M) equals\n1.7% of one year's\nprojected operating gap.",
           size = 3.0, color = csu_colors$gray_dark, fontface = "italic", lineheight = 1.15) +
  scale_fill_manual(values = c(
    "Core Cliff Driver"  = csu_colors$steel,
    "Scenario Range"     = csu_colors$rust_light,
    "Total FY28 Gap"     = csu_colors$rust,
    "One-Time Severance" = csu_colors$gold_fill
  ), guide = "none") +
  scale_x_continuous(breaks = wf_df$id, labels = wf_df$label) +
  scale_y_continuous(
    limits = c(0, 84),
    breaks = seq(0, 80, 20),
    labels = function(x) paste0("$", x, "M"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Ledger A: What Drives the Immediate $61.3M-$70.7M FY28 Operating Gap?",
    subtitle = "Enrollment mix shifts, expiring FY27 one-time bridges, and mandatory cost escalation<br>account for the **projected $61.3M-$70.7M recurring gap** alongside flat state support.",
    x = NULL,
    y = "Incremental Annual Budget Impact ($ Millions)",
    caption = paste(
      "Sources: CSU President Oct. 7, 2026 Budget Message ($61.3M-$70.7M V1.0 gap, ~$25M enrollment drop); May 13, 2026 V4 Slide 6",
      "($15.11M expiring FY27 one-time savings); Fall Budget Forum Oct. 14, 2026 (Fall 2026 census -2.5% RI, -9.7% Dom NR UG; OSPB -$1.5B state gap).",
      sep = "\n"
    )
  ) +
  theme_csu(base_size = 11, grid_axis = "y") +
  theme(axis.text.x = element_text(size = 9.5, face = "bold", color = csu_colors$slate))

save_csu_fig(fig1, "fig01_fy28_shortfall_bridge", width = 10.6, height = 6.3)

# ==============================================================================
# FIGURE 2: LEDGER B — STRUCTURAL "BLAME PIE" WITH ATTRIBUTION RANGES
# ==============================================================================
message("--- Building Figure 2: Ledger B Structural Blame Pie ---")

bp_df <- blame_pie |>
  mutate(
    driver_wrap = factor(
      case_when(
        bucket_order == 1L ~ "1. E&G Workforce Growth &\n    Incremental Budgeting (General Fund Only)",
        bucket_order == 2L ~ "2. Long-Term Capital Commitments &\n    Debt Service (Canvas, Spur, Campus)",
        bucket_order == 3L ~ "3. Athletics Net Operating Subsidy\n    (Excl. Stadium Debt to Avoid Double-Count)",
        bucket_order == 4L ~ "4. State Funding Constraints, Tuition\n    Discounting & Research F&A Limits"
      ),
      levels = rev(c(
        "1. E&G Workforce Growth &\n    Incremental Budgeting (General Fund Only)",
        "2. Long-Term Capital Commitments &\n    Debt Service (Canvas, Spur, Campus)",
        "3. Athletics Net Operating Subsidy\n    (Excl. Stadium Debt to Avoid Double-Count)",
        "4. State Funding Constraints, Tuition\n    Discounting & Research F&A Limits"
      ))
    ),
    bar_col = c(csu_colors$forest, csu_colors$slate, csu_colors$rust, csu_colors$gold),
    anchor_short = c(
      "40-50%  |  E&G Admin Pro +62% & E&G Faculty +43% (FY15-25)\nwhile Resident FTE fell -5%; 3% comp pool = $33.7M/yr",
      "20-25%  |  System debt doubled $672M (FY13) -> $1.33B (FY25)\nE&G Central Debt Service more than tripled ($10.2M -> $31.9M)",
      "15-20%  |  $75.2M gross -> $26.0M Univ support - $10.9M aid flow-back\n= ~$15.6M net operating support ($17.2M B2 E&G base)",
      "15-20%  |  State FFS+COF flat at $211M (23.4% of state-approp)\nSystem discount rate rose 17.9% -> 21.3% ($174.1M allowance)"
    )
  )

fig2 <- ggplot(bp_df, aes(y = driver_wrap, x = mid_pct)) +
  geom_col(aes(fill = I(bar_col)), width = 0.54, alpha = 0.88) +
  geom_errorbar(aes(xmin = low_pct, xmax = high_pct), orientation = "y",
                width = 0.20, linewidth = 1.0, color = csu_colors$slate) +
  geom_point(aes(x = mid_pct), size = 2.8, color = csu_colors$white) +
  geom_text(aes(x = high_pct + 1.8, label = anchor_short),
            hjust = 0, size = 2.95, fontface = "bold", color = csu_colors$slate, lineheight = 1.15) +
  scale_x_continuous(
    limits = c(0, 108),
    breaks = seq(0, 60, 15),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Ledger B: Multi-Year Structural Cost & Revenue Pressures",
    subtitle = "Approximate order-of-magnitude shares (summing to 100%) paired with **audited primary baseline figures**.<br>Reasonable observers may weight these multi-year factors differently; each plays a meaningful role.",
    x = "Illustrative Share of Multi-Year Structural Pressure (Midpoint & Sensitivity Range)",
    y = NULL,
    caption = paste(
      "Methodology note: Attribution weights synthesize permanent E&G expenditure shares and fixed obligation rigidities; audited dollar anchors come directly",
      "from CSU Fact Book FY27 (Tables 107-128), CDHE Budget Data Books (FY15-27), CSU System Audits (FY15-25), and Colorado OSA NCAA AUP FY25 (2516F-B).",
      sep = "\n"
    )
  ) +
  theme_csu(base_size = 11, grid_axis = "x") +
  theme(
    axis.text.y = element_text(size = 9.3, face = "bold", color = csu_colors$slate),
    plot.margin = margin(14, 24, 12, 14)
  )

save_csu_fig(fig2, "fig02_structural_blame_pie", width = 11.8, height = 6.0)

# ==============================================================================
# FIGURE 3: 10-YEAR E&G WORKFORCE OVERSHOOT + CEMML / SOFT-MONEY DISTINCTION
# ==============================================================================
message("--- Building Figure 3: 10-Year E&G Overshoot & CEMML Distinction ---")

eg_emp_series <- wf_cohorts |>
  filter(cohort %in% c("Admin Professional", "Tenured & TT Faculty", "State Classified Staff")) |>
  mutate(
    idx_val = ifelse(cohort == "State Classified Staff" & fiscal_year %in% 2021:2024, NA_real_, idx15_eg),
    series = case_when(
      cohort == "Admin Professional" ~ "E&G Admin Professional FTE",
      cohort == "Tenured & TT Faculty" ~ "E&G Tenured & TT Faculty FTE",
      cohort == "State Classified Staff" ~ "E&G State Classified FTE"
    )
  ) |>
  select(fiscal_year, series, idx_val)

eg_fac_tot <- wf_cohorts |>
  filter(cohort %in% c("Tenured & TT Faculty", "NTT / CCA & Adjunct Faculty")) |>
  group_by(fiscal_year) |>
  summarise(eg_fte = sum(eg_fte, na.rm = TRUE), .groups = "drop") |>
  mutate(
    idx_val = 100 * eg_fte / eg_fte[fiscal_year == 2015L],
    series = "E&G Total Faculty FTE (incl. CCA)"
  ) |>
  select(fiscal_year, series, idx_val)

stu_series <- bdb_real |>
  filter(fiscal_year >= 2015L, fiscal_year <= 2026L) |>
  select(fiscal_year, idx15_res_fte, idx15_nr_fte) |>
  pivot_longer(-fiscal_year, names_to = "k", values_to = "idx_val") |>
  mutate(series = ifelse(k == "idx15_res_fte", "Resident Student FTE", "Non-Resident Student FTE")) |>
  select(fiscal_year, series, idx_val)

tuition_series <- real_aud |>
  select(fiscal_year, idx_val = idx15_real_net_tuition) |>
  mutate(series = "Real System Net Tuition (FY25 $)")

panel_a_df <- bind_rows(eg_emp_series, eg_fac_tot, stu_series, tuition_series)
sc_bridge <- panel_a_df |>
  filter(series == "E&G State Classified FTE", fiscal_year %in% c(2020L, 2025L))

end_labels_a <- panel_a_df |>
  filter(!is.na(idx_val)) |>
  group_by(series) |>
  slice_max(fiscal_year, n = 1) |>
  ungroup() |>
  mutate(
    lbl = sprintf("%s: %.0f (%+.1f%%)",
                  recode(series,
                    "E&G Admin Professional FTE" = "E&G Admin Pro",
                    "E&G Total Faculty FTE (incl. CCA)" = "E&G All Faculty",
                    "Non-Resident Student FTE" = "Non-Resident Student FTE",
                    "Real System Net Tuition (FY25 $)" = "Real Net Tuition",
                    "E&G Tenured & TT Faculty FTE" = "E&G Tenured/TT",
                    "Resident Student FTE" = "Resident Student FTE",
                    "E&G State Classified FTE" = "E&G State Classified"
                  ),
                  idx_val, idx_val - 100),
    y_nudge = case_when(
      series == "E&G Admin Professional FTE" ~ 163.5,
      series == "E&G Total Faculty FTE (incl. CCA)" ~ 147.0,
      series == "Non-Resident Student FTE" ~ 138.0,
      series == "Real System Net Tuition (FY25 $)" ~ 109.5,
      series == "E&G Tenured & TT Faculty FTE" ~ 101.0,
      series == "Resident Student FTE" ~ 92.0,
      series == "E&G State Classified FTE" ~ 56.0
    )
  )

pal_a <- c(
  "E&G Admin Professional FTE"        = csu_colors$rust,
  "E&G Total Faculty FTE (incl. CCA)" = csu_colors$forest,
  "Non-Resident Student FTE"          = csu_colors$steel,
  "Real System Net Tuition (FY25 $)"  = csu_colors$gold,
  "E&G Tenured & TT Faculty FTE"      = csu_colors$forest_mid,
  "Resident Student FTE"              = csu_colors$slate,
  "E&G State Classified FTE"          = csu_colors$gray_mid
)

p3a <- ggplot(panel_a_df, aes(x = fiscal_year, y = idx_val, color = series)) +
  geom_hline(yintercept = 100, linetype = "dotted", color = csu_colors$gray_mid, linewidth = 0.6) +
  geom_line(data = sc_bridge, linetype = "dashed", linewidth = 0.9, alpha = 0.7) +
  geom_line(linewidth = 1.25, na.rm = TRUE) +
  geom_point(data = panel_a_df |> filter(fiscal_year %in% c(2015, 2020, 2025, 2026) & !is.na(idx_val)),
             size = 2.0) +
  geom_text(
    data = end_labels_a,
    aes(x = fiscal_year + 0.18, y = y_nudge, label = lbl, color = series),
    hjust = 0, size = 3.05, fontface = "bold", show.legend = FALSE
  ) +
  annotate("label", x = 2019.2, y = 166,
           label = "Key Context: Both E&G Faculty (+43%) & E&G Admin Pro (+62%)\ngrew over FY15-FY25 while Resident FTE declined (-5%)\nand Real Net Tuition rose +4.4%.",
           size = 2.85, fill = "#FAFBF9", color = csu_colors$slate, linewidth = 0.3, hjust = 0.5) +
  scale_color_manual(values = pal_a, guide = "none") +
  scale_x_continuous(breaks = 2015:2026, limits = c(2015, 2030.4)) +
  scale_y_continuous(limits = c(48, 178), breaks = seq(60, 180, 20)) +
  labs(
    title = "A. Ten-Year E&G Workforce & Enrollment Trends (FY2015 = 100, Education & General Funds Only)",
    subtitle = "Isolating E&G general funds shows **E&G Admin Pro (+62.3%)** and **CCA-driven E&G Faculty (+43.3%)** grew<br>faster than Resident Student FTE (-5.0%), Real Net Tuition (+4.4%), and FY26 Non-Resident FTE (-7.7% YoY).",
    x = "Fiscal Year",
    y = "Index (FY2015 = 100)"
  ) +
  theme_csu(base_size = 10.5, grid_axis = "y")

ap_plot_df <- ap_summary |>
  mutate(macro_bucket = fct_reorder(macro_bucket, total_fte)) |>
  select(macro_bucket, `Education & General (Tuition/State Base)` = eg_fte,
         `Non-E&G (Sponsored Research, Recharge, Auxiliaries, Other)` = other_funds_fte,
         total_fte, non_eg_share) |>
  pivot_longer(
    cols = c(`Education & General (Tuition/State Base)`, `Non-E&G (Sponsored Research, Recharge, Auxiliaries, Other)`),
    names_to = "fund_type",
    values_to = "fte"
  ) |>
  mutate(fund_type = factor(fund_type, levels = c(
    "Non-E&G (Sponsored Research, Recharge, Auxiliaries, Other)",
    "Education & General (Tuition/State Base)"
  )))

p3b <- ggplot(ap_plot_df, aes(y = macro_bucket, x = fte, fill = fund_type)) +
  geom_col(width = 0.65) +
  geom_text(
    data = ap_summary |> mutate(macro_bucket = fct_reorder(macro_bucket, total_fte)),
    aes(x = total_fte + 18, y = macro_bucket,
        label = sprintf("%.0f total  (%.0f E&G / %.0f Non-E&G | %.0f%% non-E&G)",
                        total_fte, eg_fte, other_funds_fte, 100 * non_eg_share)),
    inherit.aes = FALSE, hjust = 0, size = 2.95, fontface = "bold", color = csu_colors$slate
  ) +
  scale_fill_manual(
    values = c(
      "Non-E&G (Sponsored Research, Recharge, Auxiliaries, Other)" = csu_colors$sage,
      "Education & General (Tuition/State Base)"                   = csu_colors$rust
    ),
    name = "FY25 Funding Source:"
  ) +
  scale_x_continuous(limits = c(0, 2350), breaks = seq(0, 1500, 300), labels = comma) +
  labs(
    title = "B. Disaggregating Campus Staff by Funding Source: 69.7% of Admin Pro FTE Are Non-E&G (FY25)",
    subtitle = "Externally and self-funded units—across **Natural Resources (96.3% non-E&G)**, **Ag/Ext/CSFS (92.1%)**, **CVMBS (91.4%)**, and **Engineering (82.1%)**—<br>scale with sponsored awards and service revenue rather than E&G tuition; **62.1% of E&G Admin Pro** sit in Central VP & Admin units.",
    x = "FY2025 Administrative Professional FTE (by Actual Salary Distribution)",
    y = NULL,
    caption = paste(
      "Sources: CSU Fact Book FY27 (Tables 107-128 & Table 124, pp. 114-140); CDHE Budget Data Books Format 30 (FY15-FY26); CSU System Audits (FY15-FY25) CPI-U adjusted.",
      "Note: E&G State Classified FTE FY21-24 omitted from Fact Book Table 128 breakdown (plotted dashed to FY25 Table 126 actual = 316.7 FTE). E&G NTT/CCA Faculty rose from 84 to 456 FTE.",
      sep = "\n"
    )
  ) +
  theme_csu(base_size = 10.5, grid_axis = "x") +
  theme(axis.text.y = element_text(size = 9.2, face = "bold", color = csu_colors$slate))

fig3 <- p3a / p3b + plot_layout(heights = c(1.15, 1.0))
save_csu_fig(fig3, "fig03_workforce_overshoot_and_cemml", width = 12.2, height = 10.8)

# ==============================================================================
# FIGURE 4: ATHLETICS GROSS VS. NET REALITY CHECK & DEBT PEERS
# ==============================================================================
message("--- Building Figure 4: Athletics Gross vs Net & Debt Peers ---")

ath25_wf <- tibble(
  id = 1:6,
  item = c(
    "Gross\nSpending",
    "Self-Gen.\nRevenue",
    "Student\nFees",
    "Gross Univ.\nSupport*",
    "Less: Aid\nFlow-Back",
    "Net Univ.\nSupport"
  ),
  ymin = c(0,      42.59,  36.45,  0,      15.57, 0),
  ymax = c(75.24,  75.24,  42.59,  26.50,  26.50, 15.57),
  lbl  = c("$75.2M", "-$42.6M\n(Earned)", "-$6.1M\n(Fees)", "$26.5M*\n(Univ.)", "-$10.9M\n(Tuition)", "~$15.6M\n(Net)"),
  grp  = c("Gross Outflow", "Offset", "Fee Offset", "Gross Support", "Campus Flow-Back", "Net Drag")
)

p4a <- ggplot(ath25_wf, aes(x = id)) +
  geom_vline(xintercept = 3.5, linetype = "dotted", color = csu_colors$slate, linewidth = 0.55) +
  geom_rect(aes(xmin = id - 0.34, xmax = id + 0.34, ymin = ymin, ymax = ymax, fill = grp), alpha = 0.92) +
  geom_text(aes(y = ymax + 2.2, label = lbl), vjust = 0, size = 2.95, fontface = "bold", color = csu_colors$slate, lineheight = 1.1) +
  scale_fill_manual(values = c(
    "Gross Outflow"    = csu_colors$slate,
    "Offset"           = csu_colors$steel,
    "Fee Offset"       = csu_colors$gold_fill,
    "Gross Support"    = csu_colors$rust_light,
    "Campus Flow-Back" = csu_colors$sage,
    "Net Drag"         = csu_colors$rust
  ), guide = "none") +
  scale_x_continuous(breaks = ath25_wf$id, labels = ath25_wf$item) +
  scale_y_continuous(limits = c(0, 89), breaks = seq(0, 80, 20), labels = function(x) paste0("$", x, "M")) +
  labs(
    title = "A. Gross Spending vs. Net Institutional Support (FY25)",
    subtitle = "Reconciling $75.2M gross Athletics budget to ~$15.6M net operating support.",
    x = NULL,
    y = "Dollars ($ Millions)"
  ) +
  theme_csu(base_size = 10, grid_axis = "y") +
  theme(axis.text.x = element_text(size = 8.6, face = "bold", color = csu_colors$slate))

ath_debt_plot <- ath_peers |>
  mutate(
    entity = fct_reorder(entity, athletics_debt_m),
    is_csu = grepl("^Colorado State", entity)
  )

p4b <- ggplot(ath_debt_plot, aes(y = entity, x = athletics_debt_m, fill = is_csu)) +
  geom_col(width = 0.54) +
  geom_text(aes(label = sprintf("$%.1fM", athletics_debt_m)),
            hjust = -0.12, size = 3.2, fontface = "bold", color = csu_colors$slate) +
  scale_fill_manual(values = c("TRUE" = csu_colors$rust, "FALSE" = csu_colors$steel), guide = "none") +
  scale_x_continuous(limits = c(0, 255), breaks = seq(0, 200, 50), labels = function(x) paste0("$", x, "M")) +
  labs(
    title = "B. Athletics Long-Term Debt vs. Peer Benchmarks",
    subtitle = "Athletics accounts for 18.5% of CSU Fort Collins debt ($207M of $1.12B).",
    x = "Outstanding Athletics-Related Debt ($ Millions)",
    y = NULL
  ) +
  theme_csu(base_size = 10, grid_axis = "x") +
  theme(axis.text.y = element_text(size = 8.8, face = "bold", color = csu_colors$slate))

fig4 <- (p4a + p4b) + plot_layout(widths = c(1.05, 1.0)) +
  plot_annotation(
    caption = paste(
      "Sources: Panel A — Colorado OSA CSU Athletics NCAA AUP Report FY25 (2516F-B, p.24): $74.74M rev, $75.24M exp, -$0.50M deficit (*Gross Univ. = $23.85M direct + $2.15M indirect",
      "+ $0.50M deficit). Panel B — OSA Report 2516F-B Note 5 (CSU $206.96M); OSA Report 2505F-B Note 5 (CU Boulder $138.8M bonds + $38.2M internal loan); U.S. GAO-26-108640 (AY23-24 medians).",
      sep = "\n"
    ),
    theme = theme(plot.caption = element_text(size = 8.2, color = csu_colors$gray_mid, hjust = 0))
  )

save_csu_fig(fig4, "fig04_athletics_gross_vs_net", width = 12.6, height = 5.9)

# ==============================================================================
# FIGURE 5: E&G DIVISION BUDGETS & TUITION DISCOUNTING OVER TIME (FY15-FY26)
# ==============================================================================
message("--- Building Figure 5: Division Budget Shares & Tuition Discounting ---")

div_long <- div_shares |>
  transmute(
    fiscal_year,
    `Total State-Approp. Budget` = grand_total / 1e6,
    `Academic Colleges (E&G)` = colleges_total / 1e6,
    `Support & Admin Divisions` = (support_div_total + presidents_div_total) / 1e6,
    `Institutional Financial Aid` = inst_aid_budget_eg / 1e6,
    `Central Debt Service (XA)` = xa_debt_service / 1e6,
    `Athletics E&G Allocation (B2)` = b2_athletics_eg / 1e6
  ) |>
  pivot_longer(-fiscal_year, names_to = "line", values_to = "dollars_m") |>
  group_by(line) |>
  mutate(idx15 = 100 * dollars_m / dollars_m[fiscal_year == 2015L]) |>
  ungroup()

end_lbl_5a <- div_long |>
  filter(fiscal_year == 2026L) |>
  mutate(
    lbl = sprintf("%s ($%.1fM | %+.0f%%)",
                  recode(line,
                    "Central Debt Service (XA)" = "Debt Service",
                    "Institutional Financial Aid" = "Inst. Aid",
                    "Support & Admin Divisions" = "Support/Admin*",
                    "Academic Colleges (E&G)" = "Colleges*",
                    "Athletics E&G Allocation (B2)" = "Athletics (B2)",
                    "Total State-Approp. Budget" = "State-Approp."
                  ), dollars_m, idx15 - 100),
    y_nudge = case_when(
      line == "Central Debt Service (XA)" ~ 314,
      line == "Institutional Financial Aid" ~ 289,
      line == "Support & Admin Divisions" ~ 225,
      line == "Academic Colleges (E&G)" ~ 184,
      line == "Athletics E&G Allocation (B2)" ~ 166,
      line == "Total State-Approp. Budget" ~ 148
    )
  )

pal_5a <- c(
  "Central Debt Service (XA)"     = csu_colors$rust,
  "Institutional Financial Aid"   = csu_colors$gold,
  "Support & Admin Divisions"     = csu_colors$slate,
  "Academic Colleges (E&G)"       = csu_colors$forest,
  "Athletics E&G Allocation (B2)" = csu_colors$rust_light,
  "Total State-Approp. Budget"    = csu_colors$steel
)

p5a <- ggplot(div_long, aes(x = fiscal_year, y = idx15, color = line)) +
  geom_vline(xintercept = 2025.3, linetype = "dashed", color = csu_colors$gray_mid, linewidth = 0.5) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 1.8) +
  geom_text(
    data = end_lbl_5a,
    aes(x = 2026.2, y = y_nudge, label = lbl, color = line),
    hjust = 0, size = 2.9, fontface = "bold", show.legend = FALSE
  ) +
  annotate("text", x = 2024.9, y = 307,
           label = "*FY26 fringe pool\ndecentralized into\nunits (-$111M\nfrom XA central)",
           hjust = 1, size = 2.65, color = csu_colors$gray_dark, fontface = "italic", lineheight = 1.1) +
  scale_color_manual(values = pal_5a, guide = "none") +
  scale_x_continuous(breaks = seq(2015, 2026, 2), limits = c(2015, 2033.2)) +
  scale_y_continuous(limits = c(95, 330), breaks = seq(100, 300, 50)) +
  labs(
    title = "A. Nominal Growth of E&G Budget Lines (FY15 = 100)",
    subtitle = "Debt service (+213%) & Institutional Aid (+191%) grew fastest.",
    x = "Fiscal Year",
    y = "Index (FY2015 = 100)"
  ) +
  theme_csu(base_size = 10, grid_axis = "y")

disc_df <- real_aud |>
  select(fiscal_year, discount_rate = system_tuition_discount_rate, schol_m = system_schol_allowance_m) |>
  left_join(bdb_real |> filter(status == "Actual") |> select(fiscal_year, nr_share_fte), by = "fiscal_year")

p5b <- ggplot(disc_df, aes(x = fiscal_year)) +
  geom_line(aes(y = discount_rate * 100, color = "Tuition Discount Rate (Schol. Allow. / Gross Tuition)"), linewidth = 1.25) +
  geom_point(aes(y = discount_rate * 100, color = "Tuition Discount Rate (Schol. Allow. / Gross Tuition)"), size = 2.2) +
  geom_line(aes(y = nr_share_fte * 100, color = "Non-Resident Share of Student FTE (E&G)"), linewidth = 1.25) +
  geom_point(aes(y = nr_share_fte * 100, color = "Non-Resident Share of Student FTE (E&G)"), size = 2.2) +
  geom_text(
    data = disc_df |> filter(fiscal_year %in% c(2015, 2018, 2021, 2025)),
    aes(y = discount_rate * 100, label = sprintf("%.1f%%", discount_rate * 100)),
    vjust = 1.7, size = 2.9, fontface = "bold", color = csu_colors$rust
  ) +
  geom_text(
    data = disc_df |> filter(fiscal_year %in% c(2015, 2020, 2025)),
    aes(y = nr_share_fte * 100, label = sprintf("%.1f%%", nr_share_fte * 100)),
    vjust = -0.9, size = 2.9, fontface = "bold", color = csu_colors$steel
  ) +
  geom_point(data = bdb_real |> filter(fiscal_year == 2026L),
             aes(x = fiscal_year, y = nr_share_fte * 100), color = csu_colors$steel, size = 2.5) +
  geom_line(data = bdb_real |> filter(fiscal_year %in% 2025:2026),
            aes(x = fiscal_year, y = nr_share_fte * 100), color = csu_colors$steel, linewidth = 1.25) +
  geom_text(data = bdb_real |> filter(fiscal_year == 2026L),
            aes(x = fiscal_year, y = nr_share_fte * 100, label = sprintf("%.1f%%\n(FY26)", nr_share_fte * 100)),
            vjust = -0.6, size = 2.8, fontface = "bold", color = csu_colors$steel, lineheight = 1.0) +
  scale_color_manual(
    values = c(
      "Tuition Discount Rate (Schol. Allow. / Gross Tuition)" = csu_colors$rust,
      "Non-Resident Share of Student FTE (E&G)" = csu_colors$steel
    ),
    name = NULL
  ) +
  scale_x_continuous(breaks = seq(2015, 2026, 2), limits = c(2015, 2026.9)) +
  scale_y_continuous(limits = c(14, 41), labels = function(x) paste0(x, "%")) +
  labs(
    title = "B. Tuition Discount Rate vs. Non-Resident Mix (FY15-FY26)",
    subtitle = "System discount rate reached 21.3% ($174.1M) as non-resident share softened.",
    x = "Fiscal Year",
    y = "Percentage (%)"
  ) +
  theme_csu(base_size = 10, grid_axis = "y") +
  theme(legend.direction = "vertical")

fig5 <- (p5a + p5b) + plot_layout(widths = c(1.25, 1.0)) +
  plot_annotation(
    caption = paste(
      "Sources: Panel A — CSU Office of Budgets College/Division Operating Budget Summaries (FY15-FY26); Institutional Aid reconciles FY19 $41.6M move from XA to P1;",
      "FY26 fringe decentralization ($111.3M in FY25 XA) explains unit jumps in FY26. Panel B — CSU System Audited SRECNP (FY15-FY25) & CDHE BDB Format 30 (FY15-FY26).",
      sep = "\n"
    ),
    theme = theme(plot.caption = element_text(size = 8.2, color = csu_colors$gray_mid, hjust = 0))
  )

save_csu_fig(fig5, "fig05_division_shares_discounting", width = 12.6, height = 6.1)

# ==============================================================================
# FIGURE 6: 2023 IPEDS PEER BENCHMARKS (8 COLORADO & LAND-GRANT R1s)
# ==============================================================================
message("--- Building Figure 6: 2023 IPEDS Peer Benchmarks ---")

peer_long <- peer_2023 |>
  transmute(
    short_name,
    is_csu,
    `State Support / Student FTE ($)` = state_per_fte,
    `Long-Term Debt / Student FTE ($)` = debt_per_fte,
    `Net Tuition Share of Revenue (%)` = tuition_share_rev * 100,
    `Non-Instructional / Inst. Staff Ratio` = noninst_to_inst_ratio
  ) |>
  pivot_longer(-c(short_name, is_csu), names_to = "metric", values_to = "val") |>
  mutate(
    metric = factor(metric, levels = c(
      "State Support / Student FTE ($)",
      "Long-Term Debt / Student FTE ($)",
      "Net Tuition Share of Revenue (%)",
      "Non-Instructional / Inst. Staff Ratio"
    ))
  )

make_peer_panel <- function(df, m, fmt_fn, x_max, axis_fmt) {
  sub <- df |>
    filter(metric == m) |>
    mutate(short_name = fct_reorder(short_name, val))
  ggplot(sub, aes(y = short_name, x = val, fill = is_csu)) +
    geom_col(width = 0.62) +
    geom_text(aes(label = fmt_fn(val)), hjust = -0.1, size = 3.0, fontface = "bold", color = csu_colors$slate) +
    scale_fill_manual(values = c("TRUE" = csu_colors$forest, "FALSE" = "#B4C2BC"), guide = "none") +
    scale_x_continuous(limits = c(0, x_max), labels = axis_fmt, expand = expansion(mult = c(0, 0.02))) +
    labs(title = m, x = NULL, y = NULL) +
    theme_csu(base_size = 9.5, grid_axis = "x") +
    theme(
      plot.title = element_text(size = 10.5, face = "bold", color = csu_colors$slate),
      axis.text.y = element_text(size = 8.8, face = "bold")
    )
}

p6_1 <- make_peer_panel(peer_long, "State Support / Student FTE ($)", function(x) paste0("$", comma(round(x))), 22000, dollar)
p6_2 <- make_peer_panel(peer_long, "Long-Term Debt / Student FTE ($)", function(x) paste0("$", comma(round(x))), 130000, dollar)
p6_3 <- make_peer_panel(peer_long, "Net Tuition Share of Revenue (%)", function(x) sprintf("%.1f%%", x), 49, function(x) paste0(x, "%"))
p6_4 <- make_peer_panel(peer_long, "Non-Instructional / Inst. Staff Ratio", function(x) sprintf("%.2fx", x), 4.8, function(x) paste0(x, "x"))

fig6 <- (p6_1 + p6_2) / (p6_3 + p6_4) +
  plot_annotation(
    title = "Peer Context (2023 IPEDS): State Funding, Debt Load, Tuition Reliance & Staffing",
    subtitle = "Across 5 R1 land-grants and 2 Colorado peers, CSU receives less than half the state support/FTE of WA/UT/KS,<br>carries ~$38.9k/FTE in debt, and sits mid-pack on all-funds staff ratio (3.29x, which includes sponsored research & extension).",
    caption = paste(
      "Source: U.S. Dept. of Education IPEDS (2023 Finance, FTE Enrollment, and Human Resources via Urban Institute Education Data Portal).",
      "Note: IPEDS non-instructional headcount combines general-fund staff with externally funded research, clinical, extension, and auxiliary employees.",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(size = 13.5, face = "bold", color = csu_colors$slate),
      plot.subtitle = element_markdown(size = 9.5, color = csu_colors$gray_dark, lineheight = 1.25),
      plot.caption = element_text(size = 8.0, color = csu_colors$gray_mid, hjust = 0)
    )
  )

save_csu_fig(fig6, "fig06_peer_landgrant_benchmarks", width = 11.6, height = 7.6)
message("=== 04_make_figures.R COMPLETE ===")
