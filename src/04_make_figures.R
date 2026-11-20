# 04_make_figures.R
# Generates all 6 publication-grade ggplot2 figures (300-DPI PNG & vector SVG)
# into outputs/figures/.

source(file.path(if (dir.exists("src")) "src" else ".", "00_setup_theme.R"))

proc_dir <- file.path(PROJECT_ROOT, "data", "processed")

fy28_bridge <- read_csv(file.path(proc_dir, "fy28_shortfall_bridge.csv"), show_col_types = FALSE)
blame_pie   <- read_csv(file.path(proc_dir, "structural_blame_pie.csv"), show_col_types = FALSE)
wf_cohorts  <- read_csv(file.path(proc_dir, "workforce_cohorts_fy15_fy25.csv"), show_col_types = FALSE)
fb26_cont   <- read_csv(file.path(proc_dir, "factbook_continuous_eg_fte_fy13_fy25.csv"), show_col_types = FALSE)
bdb_func    <- read_csv(file.path(proc_dir, "bdb_format20_functional_eg_fy15_fy27.csv"), show_col_types = FALSE)
ap_func_spl <- read_csv(file.path(proc_dir, "eg_ap_functional_split_fy15_fy26.csv"), show_col_types = FALSE)
ap_summary  <- read_csv(file.path(proc_dir, "cemml_ap_unit_summary_fy25.csv"), show_col_types = FALSE)
bdb_real    <- read_csv(file.path(proc_dir, "bdb_real_fy17_fy27.csv"), show_col_types = FALSE)
real_aud    <- read_csv(file.path(proc_dir, "real_audits_fy15_fy25.csv"), show_col_types = FALSE)
ath_recon   <- read_csv(file.path(proc_dir, "athletics_gross_to_net_fy25.csv"), show_col_types = FALSE)
ath_peers   <- read_csv(file.path(proc_dir, "athletics_debt_peers.csv"), show_col_types = FALSE)
div_shares  <- read_csv(file.path(proc_dir, "division_budget_shares_fy17_fy26.csv"), show_col_types = FALSE)
cpi_fy      <- read_csv(file.path(proc_dir, "macro_cpiu_fy.csv"), show_col_types = FALSE)
peer_2023   <- read_csv(file.path(proc_dir, "peer_benchmarks_2023.csv"), show_col_types = FALSE)
top_summary <- read_csv(file.path(proc_dir, "topline_takeaway_summary.csv"), show_col_types = FALSE)

# ==============================================================================
# FIGURE 0: TOPLINE TAKE-HOME FIGURE — FLASHPOINTS VS. TOTAL E&G & FY28 GAP
# ==============================================================================
message("--- Building Figure 0: Topline Takeaway Scale Comparison ---")

eg_p0 <- top_summary |>
  filter(section == "FY26 E&G Budget") |>
  mutate(
    bucket = factor(
      case_when(
        item == "Athletics E&G Base Allocation (B2)" ~ "Athletics E&G Base ($17.2M | 1.9%)",
        item == "Central E&G Capital Debt Service (XA)" ~ "Central E&G Debt Service ($31.9M | 3.6%)",
        item == "Institutional Financial Aid (E&G Discounting)" ~ "Inst. Financial Aid ($83.7M | 9.5%)",
        item == "Central Utilities, Insurance & Reserves" ~ "Utilities & Central ($38.5M | 4.4%)",
        item == "Campus Operations, Facilities, IT & Central Admin (incl. fringe)" ~ "Campus Ops, Facilities, IT & Admin ($125.6M | 14.2%)",
        TRUE ~ "Academic Colleges, Agencies & Student Support ($588.3M | 66.5%)"
      ),
      levels = c(
        "Athletics E&G Base ($17.2M | 1.9%)",
        "Central E&G Debt Service ($31.9M | 3.6%)",
        "Utilities & Central ($38.5M | 4.4%)",
        "Inst. Financial Aid ($83.7M | 9.5%)",
        "Campus Ops, Facilities, IT & Admin ($125.6M | 14.2%)",
        "Academic Colleges, Agencies & Student Support ($588.3M | 66.5%)"
      )
    )
  ) |>
  arrange(bucket) |>
  mutate(
    xmax = cumsum(share_pct) * 100,
    xmin = lag(xmax, default = 0),
    xmid = (xmin + xmax) / 2
  )

p0a <- ggplot(eg_p0) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0.70, ymax = 1.24, fill = bucket), color = "white", linewidth = 0.6) +
  annotate("segment", x = 0.2, xend = 5.45, y = 1.30, yend = 1.30, linewidth = 0.9, color = csu_colors$rust) +
  annotate("text", x = 0.2, y = 1.35,
           label = "5.5% ($49.0M): Athletics B2 + Debt Service\n(8.0% of 10-Yr E&G Budget Growth)",
           size = 2.95, fontface = "bold", color = csu_colors$rust, hjust = 0, vjust = 0, lineheight = 1.1) +
  annotate("segment", x = 5.75, xend = 99.8, y = 1.30, yend = 1.30, linewidth = 0.9, color = csu_colors$forest) +
  annotate("text", x = 52.8, y = 1.36,
           label = "94.5% ($836.1M): Core Academic Instruction, Campus Operations, Financial Aid & Admin Support",
           size = 3.05, fontface = "bold", color = csu_colors$forest, hjust = 0.5, vjust = 0) +
  geom_text(data = eg_p0 |> filter(share_pct >= 0.08),
            aes(x = xmid, y = 0.97, label = sprintf("%.1f%%", share_pct * 100)),
            color = "white", fontface = "bold", size = 3.2) +
  scale_fill_manual(values = c(
    "Athletics E&G Base ($17.2M | 1.9%)"                              = csu_colors$rust,
    "Central E&G Debt Service ($31.9M | 3.6%)"                        = csu_colors$gold,
    "Utilities & Central ($38.5M | 4.4%)"                             = "#9AA5AC",
    "Inst. Financial Aid ($83.7M | 9.5%)"                             = csu_colors$steel,
    "Campus Ops, Facilities, IT & Admin ($125.6M | 14.2%)"            = csu_colors$slate,
    "Academic Colleges, Agencies & Student Support ($588.3M | 66.5%)" = csu_colors$forest
  ), name = NULL) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(limits = c(0.58, 1.62)) +
  labs(
    title = "A. Share of CSU's $885.2M E&G Operating Budget (FY26 Official Budget)",
    subtitle = "Athletics E&G funding ($17.2M) and central debt service ($31.9M) are real commitments, yet 94.5% of E&G sits elsewhere.",
    x = NULL, y = NULL
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  theme_csu(base_size = 10, grid_axis = "x") +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.text = element_text(size = 8.4),
    legend.key.size = unit(0.38, "cm")
  )

gap_cmp_df <- tribble(
  ~row_id, ~row_lbl, ~seg, ~xmin, ~xmax, ~fill_col, ~seg_lbl,
  2, "Projected FY28 Gap\n($66.0M Midpoint)",   "Enrollment & NR Mix (-$25.0M)",    0.00, 25.00, csu_colors$steel,      "Enrollment Mix\n$25.0M",
  2, "Projected FY28 Gap\n($66.0M Midpoint)",   "Expiring 1x Stopgaps (-$15.1M)",   25.00, 40.11, csu_colors$slate,      "1x Cliff\n$15.1M",
  2, "Projected FY28 Gap\n($66.0M Midpoint)",   "Cost/Comp vs Flat State ($25.9M)", 40.11, 66.00, csu_colors$rust_light, "Cost/Comp & State\n$25.9M",
  1, "If Headline Items Were\nZeroed Out Today", "Exec Payouts (1x: $1.43M)",       0.00,  1.425, csu_colors$gold,      "",
  1, "If Headline Items Were\nZeroed Out Today", "Net Athletics Support ($15.57M)", 1.425, 16.995, csu_colors$rust,    "Net Athletics\n$15.6M (23.6%)",
  1, "If Headline Items Were\nZeroed Out Today", "Still Unresolved (~$49M-$50M/yr)",16.995, 66.00, "#E9ECEF",            "~$49M-$50M/yr (~76% of gap) REMAINS UNRESOLVED\n(Enrollment mix, per-employee cost inflation, discounting & state caps)"
)

p0b <- ggplot(gap_cmp_df) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = row_id - 0.28, ymax = row_id + 0.28, fill = I(fill_col)),
            color = "white", linewidth = 0.6) +
  geom_rect(data = gap_cmp_df |> filter(grepl("UNRESOLVED", seg_lbl)),
            aes(xmin = xmin, xmax = xmax, ymin = row_id - 0.28, ymax = row_id + 0.28),
            fill = NA, color = csu_colors$slate, linetype = "dashed", linewidth = 0.7) +
  geom_text(data = gap_cmp_df |> filter(seg_lbl != "" & !grepl("UNRESOLVED", seg_lbl)),
            aes(x = (xmin + xmax) / 2, y = row_id, label = seg_lbl),
            color = "white", fontface = "bold", size = 2.85, lineheight = 1.05) +
  geom_text(data = gap_cmp_df |> filter(grepl("UNRESOLVED", seg_lbl)),
            aes(x = (xmin + xmax) / 2, y = row_id, label = seg_lbl),
            color = csu_colors$slate, fontface = "bold", size = 2.85, lineheight = 1.1) +
  annotate("text", x = 0.7, y = 1.42,
           label = "Pres. ($1.10M) + Provost ($0.33M) 1x payouts = $1.43M (2.2% of 1 yr)",
           hjust = 0, vjust = 0, size = 2.8, fontface = "bold", color = "#7A5E10") +
  annotate("segment", x = 0.7, xend = 0.7, y = 1.40, yend = 1.28, color = "#7A5E10", linewidth = 0.55) +
  scale_y_continuous(breaks = c(1, 2), labels = c("If Headline Items Were\nZeroed Out Today", "Projected FY28 Gap\n($66.0M Midpoint)"), limits = c(0.55, 2.48)) +
  scale_x_continuous(limits = c(0, 70), breaks = seq(0, 60, 15), labels = function(x) paste0("$", x, "M"), expand = expansion(mult = c(0.01, 0.02))) +
  labs(
    title = "B. Scale Comparison Against the Projected $66.0M/yr FY28 Operating Gap ($61.3M-$70.7M)",
    subtitle = "Even eliminating 100% of net Athletics operating support and recent one-time settlements leaves roughly **76% ($50M/yr)** unresolved.",
    x = "Annual Operating Gap / Offset ($ Millions)", y = NULL
  ) +
  theme_csu(base_size = 10, grid_axis = "x") +
  theme(axis.text.y = element_text(size = 9.0, face = "bold", color = csu_colors$slate))

fig0 <- p0a / p0b + plot_layout(heights = c(1.0, 1.05)) +
  plot_annotation(
    title = "Topline Context: Headline Controversies Are Real, Yet Represent a Small Share of CSU's Gap",
    subtitle = "Audited general-fund shares (Panel A) and FY28 operating shortfall scale (Panel B) point toward broader structural drivers.",
    caption = paste(
      "Sources: CSU Office of Budgets College/Division OBS (FY15 & FY26, $885.16M total); Oct. 7, 2026 Budget Memo ($61.3M-$70.7M gap);",
      "May 13 V4 Slide 6; Colorado OSA Report 2516F-B (~$15.57M net Athletics support); 2026 public transition settlements ($1.10M Pres. + $0.325M Provost).",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(size = 13.5, face = "bold", color = csu_colors$slate),
      plot.subtitle = element_text(size = 10.0, color = csu_colors$gray_dark),
      plot.caption = element_text(size = 8.0, color = csu_colors$gray_mid, hjust = 0)
    )
  )

save_csu_fig(fig0, "fig00_topline_takeaway", width = 12.0, height = 7.1)

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
    "Context: Pres. +\nProvost Payouts"
  ),
  ymin = c(0, 25.00, 40.11, 0, 0),
  ymax = c(25.00, 40.11, 66.00, 66.00, 1.425),
  fill_grp = c("Core Cliff Driver", "Core Cliff Driver", "Scenario Range", "Total FY28 Gap", "One-Time Severance"),
  txt_lbl = c(
    "-$25.0M\n(~38% of gap)",
    "-$15.1M\n(~23% of gap)",
    "-$25.9M\n(-$21.2M to -$30.6M)",
    "-$66.0M\n($61.3M-$70.7M)",
    "$1.43M\n(2.2% of 1-yr gap)"
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
  annotate("text", x = 5, y = 20,
           label = "Scale Note:\nCombined one-time payouts\n($1.10M Pres. + $0.33M Prov.)\nequal 2.2% of one year's\nprojected operating gap.",
           size = 2.95, color = csu_colors$gray_dark, fontface = "italic", lineheight = 1.15) +
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
        bucket_order == 1L ~ "1. E&G Payroll Cost Inflation, Support Mix &\n    Incremental Budgeting (General Fund Only)",
        bucket_order == 2L ~ "2. Long-Term Capital Commitments &\n    Debt Service (Canvas, Spur, Campus)",
        bucket_order == 3L ~ "3. Athletics Net Operating Subsidy\n    (Excl. Stadium Debt to Avoid Double-Count)",
        bucket_order == 4L ~ "4. State Funding Limits, Tuition Discounting\n    & Post-2026 Ballot Context"
      ),
      levels = rev(c(
        "1. E&G Payroll Cost Inflation, Support Mix &\n    Incremental Budgeting (General Fund Only)",
        "2. Long-Term Capital Commitments &\n    Debt Service (Canvas, Spur, Campus)",
        "3. Athletics Net Operating Subsidy\n    (Excl. Stadium Debt to Avoid Double-Count)",
        "4. State Funding Limits, Tuition Discounting\n    & Post-2026 Ballot Context"
      ))
    ),
    bar_col = c(csu_colors$forest, csu_colors$slate, csu_colors$rust, csu_colors$gold),
    anchor_short = c(
      "40-50%  |  Total E&G FTE +7.0% (matching +6.6% Student FTE); Gen. Admin = 6.4%\nAcad./Student Support +39.9%; every 3% comp/fringe pool = $33.7M/yr",
      "20-25%  |  System debt doubled $672M (FY13) -> $1.33B (FY25)\nE&G Central Debt Service more than tripled ($10.2M -> $31.9M)",
      "15-20%  |  $75.2M gross -> $26.0M Univ support - $10.9M aid flow-back\n= ~$15.6M net operating support ($17.2M B2 E&G base)",
      "15-20%  |  FY27 State FFS+COF flat at $211M; Discount rate 21.3% ($174.1M)\nNov. '26 Amend. 87 (+$1.97B) eases K-12/Medicaid General Fund crowding"
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
    limits = c(0, 118),
    breaks = seq(0, 60, 15),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Ledger B: Multi-Year Structural Cost & Revenue Pressures",
    subtitle = "Order-of-magnitude illustration (summing to 100%) paired with **audited primary baseline figures**.<br>Reasonable observers may weight these multi-year factors differently; each plays a measurable role.",
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
# FIGURE 3: E&G FUNCTIONAL WORKFORCE DISAGGREGATION & NON-E&G SEPARATION
# ==============================================================================
message("--- Building Figure 3: Continuous E&G Functional Workforce, Inside Admin Pro & Non-E&G ---")

func_act <- bdb_func |>
  filter(status == "Actual", fiscal_year >= 2015L, fiscal_year <= 2026L) |>
  mutate(acad_stud_fte = acad_fte + stud_fte)

b15 <- func_act |> filter(fiscal_year == 2015L)

cdhe_lines <- bind_rows(
  func_act |> transmute(fiscal_year, series = "E&G Academic & Student Support (Fmt 1400+1500)", idx_val = 100 * acad_stud_fte / b15$acad_stud_fte),
  func_act |> transmute(fiscal_year, series = "E&G General Admin / Inst. Support (Fmt 1600)",   idx_val = 100 * inst_supp_fte / b15$inst_supp_fte),
  func_act |> transmute(fiscal_year, series = "Total E&G Workforce (CDHE Format 20)",             idx_val = 100 * tot_eg_fte / b15$tot_eg_fte),
  func_act |> transmute(fiscal_year, series = "E&G Instruction Total (Fac + Staff/GA, Fmt 1100)", idx_val = 100 * inst_fte / b15$inst_fte)
)

fb_lines <- bind_rows(
  fb26_cont |> filter(fiscal_year >= 2015L, fiscal_year <= 2025L) |>
    transmute(fiscal_year, series = "E&G Non-Faculty Staff Combined (AP + Class., FB26)", idx_val = 100 * eg_nonfac_combined / eg_nonfac_combined[fiscal_year == 2015L]),
  fb26_cont |> filter(fiscal_year >= 2015L, fiscal_year <= 2025L) |>
    transmute(fiscal_year, series = "Continuous E&G Faculty All Ranks (FB26)",            idx_val = 100 * eg_fac_total_cont / eg_fac_total_cont[fiscal_year == 2015L])
)

stu_line <- bdb_real |>
  filter(fiscal_year >= 2015L, fiscal_year <= 2026L, status == "Actual") |>
  transmute(
    fiscal_year,
    series = "Total Student FTE (CDHE Format 30)",
    idx_val = 100 * total_student_fte / total_student_fte[fiscal_year == 2015L]
  )

panel_a_df <- bind_rows(cdhe_lines, fb_lines, stu_line)

end_labels_a <- panel_a_df |>
  group_by(series) |>
  slice_max(fiscal_year, n = 1) |>
  ungroup() |>
  mutate(
    lbl = case_when(
      series == "E&G Academic & Student Support (Fmt 1400+1500)" ~ sprintf("Acad/Student Support (Fmt 1400-1500): %+.1f%%", idx_val - 100),
      series == "E&G Non-Faculty Staff Combined (AP + Class., FB26)" ~ sprintf("E&G Non-Fac AP+Class. (FB26, '25): %+.1f%%", idx_val - 100),
      series == "E&G General Admin / Inst. Support (Fmt 1600)" ~ sprintf("Central General Admin (Fmt 1600): %+.1f%%", idx_val - 100),
      series == "Continuous E&G Faculty All Ranks (FB26)" ~ sprintf("Continuous E&G Faculty (FB26, '25): %+.1f%%", idx_val - 100),
      series == "Total E&G Workforce (CDHE Format 20)" ~ sprintf("Total E&G Workforce (Fmt 20): %+.1f%%", idx_val - 100),
      series == "Total Student FTE (CDHE Format 30)" ~ sprintf("Total Student FTE (Fmt 30): %+.1f%%", idx_val - 100),
      TRUE ~ sprintf("E&G Instruction Total (Fmt 1100): %+.1f%%", idx_val - 100)
    ),
    y_nudge = case_when(
      series == "E&G Academic & Student Support (Fmt 1400+1500)" ~ 139.9,
      series == "E&G Non-Faculty Staff Combined (AP + Class., FB26)" ~ 122.0,
      series == "E&G General Admin / Inst. Support (Fmt 1600)" ~ 116.0,
      series == "Continuous E&G Faculty All Ranks (FB26)" ~ 110.8,
      series == "Total E&G Workforce (CDHE Format 20)" ~ 105.0,
      series == "Total Student FTE (CDHE Format 30)" ~ 99.6,
      TRUE ~ 94.2
    )
  )

pal_a <- c(
  "E&G Academic & Student Support (Fmt 1400+1500)"    = csu_colors$rust,
  "E&G Non-Faculty Staff Combined (AP + Class., FB26)"= csu_colors$rust_light,
  "E&G General Admin / Inst. Support (Fmt 1600)"      = csu_colors$gold,
  "Continuous E&G Faculty All Ranks (FB26)"           = csu_colors$forest,
  "Total E&G Workforce (CDHE Format 20)"              = csu_colors$slate,
  "Total Student FTE (CDHE Format 30)"                = csu_colors$steel,
  "E&G Instruction Total (Fac + Staff/GA, Fmt 1100)" = csu_colors$forest_mid
)

p3a <- ggplot(panel_a_df, aes(x = fiscal_year, y = idx_val, color = series)) +
  annotate("segment", x = 2015, xend = 2026.05, y = 100, yend = 100,
           linetype = "dotted", color = csu_colors$gray_mid, linewidth = 0.6) +
  geom_line(linewidth = 1.2) +
  geom_point(data = panel_a_df |> filter(fiscal_year %in% c(2015, 2020, 2024, 2026)), size = 1.9) +
  geom_text(
    data = end_labels_a,
    aes(x = 2026.25, y = y_nudge, label = lbl, color = series),
    hjust = 0, size = 2.8, fontface = "bold", show.legend = FALSE
  ) +
  annotate("label", x = 2015.1, y = 148,
           label = "Audit Reconciliation (FY15-FY26):\nTotal E&G FTE grew +7.0% (3,506 -> 3,752), matching Student FTE (+6.6%).\nRaw AP counts conflate -255 Classified shifts & teaching/advising roles;\nCentral General Admin (Fmt 1600) = 239.1 FTE (6.4%) after peaking in FY24.",
           size = 2.55, fill = "#FAFBF9", color = csu_colors$slate, linewidth = 0.3, hjust = 0, lineheight = 1.15) +
  scale_color_manual(values = pal_a, guide = "none") +
  scale_x_continuous(breaks = 2015:2026, limits = c(2015, 2032.4), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(limits = c(86, 162), breaks = seq(90, 160, 15)) +
  labs(
    title = "A. Continuous E&G Workforce & Enrollment Trends (FY2015 = 100, Removing Title-Code Shifts)",
    subtitle = "Total E&G FTE (**+7.0%**) tracked Total Student FTE (**+6.6%**); growth concentrated in **Academic/Student Support (+39.9%)**,<br>while Tenured Faculty fell **-13.8%** and CCA rose **+40.6%**.",
    x = "Fiscal Year",
    y = "Index (FY2015 = 100)"
  ) +
  theme_csu(base_size = 10, grid_axis = "y")

ap_func_plot <- ap_func_spl |>
  mutate(
    is_gen_admin = cdhe_format == "Fmt 1600",
    func_lbl = factor(paste0(nacubo_function, " [", cdhe_format, "]"),
                      levels = rev(paste0(nacubo_function[order(-ap_fy26)], " [", cdhe_format[order(-ap_fy26)], "]"))),
    bar_fill = ifelse(is_gen_admin, csu_colors$gold, csu_colors$steel),
    lbl_txt = sprintf("%.1f FTE (%.1f%% of E&G AP | %+.1f AP vs FY15)", ap_fy26, 100 * ap_share_fy26, ap_delta_15_26)
  )

p3b <- ggplot(ap_func_plot, aes(y = func_lbl, x = ap_fy26, fill = I(bar_fill))) +
  geom_col(width = 0.62, alpha = 0.90) +
  geom_text(aes(x = ap_fy26 + 10, label = lbl_txt),
            hjust = 0, size = 2.85, fontface = "bold", color = csu_colors$slate) +
  scale_x_continuous(limits = c(0, 820), breaks = seq(0, 500, 100), labels = comma) +
  labs(
    title = "B. Inside E&G \"Admin Pro\": Functional Roles of CSU's 1,469.2 E&G Non-Classified FTE (FY26 Actual, CDHE Fmts 1100-1700)",
    subtitle = "**85.5% (1,256.0 FTE)** work in Academic Advising/Support (33.0%), **Instruction & Teaching Labs (22.2%)**, Student Services (13.9%),<br>Research/Public Service (13.0%) & Plant (3.4%); **14.5% (213.2 AP / 239.1 total FTE)** sit in Central General Admin (Fmt 1600).",
    x = "FY2026 Actual E&G Non-Classified Staff FTE",
    y = NULL
  ) +
  theme_csu(base_size = 10, grid_axis = "x") +
  theme(axis.text.y = element_text(size = 8.9, face = "bold", color = csu_colors$slate))

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

p3c <- ggplot(ap_plot_df, aes(y = macro_bucket, x = fte, fill = fund_type)) +
  geom_col(width = 0.62) +
  geom_text(
    data = ap_summary |> mutate(macro_bucket = fct_reorder(macro_bucket, total_fte)),
    aes(x = total_fte + 18, y = macro_bucket,
        label = sprintf("%.0f total  (%.0f E&G / %.0f Non-E&G | %.0f%% non-E&G)",
                        total_fte, eg_fte, other_funds_fte, 100 * non_eg_share)),
    inherit.aes = FALSE, hjust = 0, size = 2.85, fontface = "bold", color = csu_colors$slate
  ) +
  scale_fill_manual(
    values = c(
      "Non-E&G (Sponsored Research, Recharge, Auxiliaries, Other)" = csu_colors$sage,
      "Education & General (Tuition/State Base)"                   = csu_colors$rust
    ),
    name = "FY25 Funding Source:"
  ) +
  scale_x_continuous(limits = c(0, 2380), breaks = seq(0, 1500, 300), labels = comma) +
  labs(
    title = "C. Campus-Wide Funding Split: 69.7% of All Admin Pro FTE Work Outside E&G (FY25 Fact Book Table 124)",
    subtitle = "Externally and self-funded units across **Natural Resources (96.3% non-E&G)**, **Ag/Ext/CSFS (92.1%)**, **CVMBS (91.4%)**, and **Engineering (82.1%)** scale with external awards & service revenue.",
    x = "FY2025 Administrative Professional FTE (by Actual Salary Distribution)",
    y = NULL,
    caption = paste(
      "Sources: CDHE Budget Data Books Formats 20, 25, 30 & 1100-1700 (FINAL_BDB FY15-16 through FY26-27); CSU Fact Book FY26 (pp.107-112 continuous E&G); Fact Book FY27 (Tables 123-124).",
      "Note: FY27 CDHE Estimate drops Institutional Support (Fmt 1600) to 187.4 FTE (-10.4% vs FY15) and Total E&G FTE to 3,402.5 (-9.3% vs FY26).",
      sep = "\n"
    )
  ) +
  theme_csu(base_size = 10, grid_axis = "x") +
  theme(axis.text.y = element_text(size = 8.9, face = "bold", color = csu_colors$slate))

fig3 <- p3a / p3b / p3c + plot_layout(heights = c(1.25, 0.85, 0.95))
save_csu_fig(fig3, "fig03_workforce_overshoot_and_cemml", width = 12.2, height = 11.8)

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
