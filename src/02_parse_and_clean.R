# 02_parse_and_clean.R
# Programmatically parses primary CSU PDFs, HTML memos, BLS CPI-U,
# Colorado OSA NCAA AUP reports, and IPEDS peer extracts into clean CSVs
# inside data/processed/.

source(file.path(if (dir.exists("src")) "src" else ".", "00_setup_theme.R"))

proc_dir <- file.path(PROJECT_ROOT, "data", "processed")
raw_dir  <- file.path(PROJECT_ROOT, "data", "raw")
dir.create(proc_dir, recursive = TRUE, showWarnings = FALSE)

# Helper to parse numeric strings like "$ 1,234,567" or "(45,678)" or "-"
parse_acct_num <- function(x) {
  x <- trimws(as.character(x))
  x <- gsub("\\$|,|\\s+", "", x)
  is_neg <- grepl("^\\(.*\\)$", x)
  x <- gsub("[\\(\\)]", "", x)
  x[x %in% c("", "-", "—", "–", "NA")] <- NA_character_
  val <- suppressWarnings(as.numeric(x))
  ifelse(is_neg & !is.na(val), -val, val)
}

# ==============================================================================
# 1. MACRO: BLS CPI-U FISCAL YEAR DEFLATOR (July - June = CSU Fiscal Year)
# ==============================================================================
message("--- Parsing 1: BLS CPI-U Fiscal Year Series ---")
cpi_raw <- read_csv(file.path(raw_dir, "macro", "bls_cpiu_2014_2026.csv"), show_col_types = FALSE) |>
  filter(!is.na(cpiu)) |>
  mutate(
    # CSU FY ends June 30: Jul-Dec of year Y belong to FY(Y+1); Jan-Jun of year Y belong to FY(Y)
    fy = ifelse(month >= 7L, year + 1L, year)
  )

cpi_fy <- cpi_raw |>
  filter(fy >= 2015L, fy <= 2027L) |>
  group_by(fy) |>
  summarise(
    n_months = n(),
    cpiu_fy_avg = mean(cpiu, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    fy_label = paste0("FY", substr(fy, 3, 4)),
    base_fy25 = cpiu_fy_avg[fy == 2025L],
    base_fy26 = cpiu_fy_avg[fy == 2026L],
    mult_to_fy25 = base_fy25 / cpiu_fy_avg,
    mult_to_fy26 = base_fy26 / cpiu_fy_avg,
    source_id = "bls_cpiu"
  )

write_csv(cpi_fy, file.path(proc_dir, "macro_cpiu_fy.csv"))
message("  Saved macro_cpiu_fy.csv (", nrow(cpi_fy), " fiscal years)")

# ==============================================================================
# 2. IRP&E FACT BOOK FY27: EMPLOYEE FTE BY FUND OVER TIME (FY13-FY25)
#    AND BY UNIT (FY25) — ISOLATING E&G VS. SOFT-MONEY RESEARCH (CEMML/CIRA)
# ==============================================================================
message("--- Parsing 2: Fact Book FY27 Employee FTE by Fund & Unit ---")
fb27_txt <- pdf_text(file.path(raw_dir, "irpe", "CSU_Factbook_FY27_2026-10-22.pdf"))
fb26_txt <- pdf_text(file.path(raw_dir, "irpe", "CSU_Factbook_FY26.pdf"))

parse_fb_fund_over_time <- function(page_text, emp_group) {
  lines <- strsplit(page_text, "\n")[[1]]
  # Keep rows beginning with 4-digit year 2013..2025
  yr_lines <- grep("^\\s*(201[3-9]|202[0-5])\\s+", lines, value = TRUE)
  # Check column header structure from page_text
  has_four_cols <- grepl("Auxiliaries", page_text) && grepl("Recharge", page_text)
  rows <- map_dfr(yr_lines, function(ln) {
    nums <- as.numeric(gsub(",", "", regmatches(ln, gregexpr("[0-9,]+\\.[0-9]+", ln))[[1]]))
    yr <- as.integer(str_extract(trimws(ln), "^20[0-9]{2}"))
    if (!has_four_cols) {
      # Standard 3-col: E&G | Other Funds | Total (some early rows omit Other Funds when 0)
      if (length(nums) == 3) {
        tibble(fiscal_year = yr, employee_group = emp_group, eg_fte = nums[1], other_funds_fte = nums[2], total_fte = nums[3])
      } else if (length(nums) == 2) {
        tibble(fiscal_year = yr, employee_group = emp_group, eg_fte = nums[1], other_funds_fte = 0, total_fte = nums[2])
      } else {
        tibble()
      }
    } else {
      # Table 128 State Classified special formatting: FY13-20 have E&G, Other, Total;
      # FY21-24 have Other+E&G combined in col2, Aux in col3, Total; FY25 has Other/Aux/E&G, Recharge, Total
      if (yr <= 2020L && length(nums) == 3) {
        tibble(fiscal_year = yr, employee_group = emp_group, eg_fte = nums[1], other_funds_fte = nums[2], total_fte = nums[3])
      } else {
        tibble(fiscal_year = yr, employee_group = emp_group, eg_fte = NA_real_, other_funds_fte = NA_real_, total_fte = tail(nums, 1))
      }
    }
  })
  rows
}

fte_fund_list <- list(
  parse_fb_fund_over_time(fb27_txt[119], "Tenured Faculty"),
  parse_fb_fund_over_time(fb27_txt[122], "Tenure-Track Faculty"),
  parse_fb_fund_over_time(fb27_txt[125], "Contract Faculty"),
  parse_fb_fund_over_time(fb27_txt[128], "Continuing Faculty"),
  parse_fb_fund_over_time(fb27_txt[131], "Adjunct Faculty"),
  parse_fb_fund_over_time(fb27_txt[134], "Transitional Faculty"),
  parse_fb_fund_over_time(fb27_txt[137], "Administrative Professional"),
  parse_fb_fund_over_time(fb27_txt[140], "State Classified"),
  parse_fb_fund_over_time(fb27_txt[143], "Graduate Assistant")
)

# Note: In Fact Book FY27 Table 126 (p.138), FY25 State Classified E&G FTE = 316.7 (and Total = 1333.7;
# Table 128 reports total = 1333.8 due to rounding). Also extract FY25 AP by detailed fund from Table 123 (p.135).
fte_by_fund <- bind_rows(fte_fund_list) |>
  mutate(
    eg_fte = ifelse(employee_group == "State Classified" & fiscal_year == 2025L, 316.7, eg_fte),
    other_funds_fte = ifelse(employee_group == "State Classified" & fiscal_year == 2025L, total_fte - 316.7, other_funds_fte),
    source_id = "factbook_fy27",
    source_note = ifelse(employee_group == "State Classified" & fiscal_year %in% 2021:2024,
                         "FB27 Table 128 aggregates E&G+Other for FY21-24; FY25 E&G (316.7) from Table 126.",
                         "FB27 Tables 107,110,113,116,119,122,125,126,128,131")
  )

# Complete missing 2013/2014 zero rows for Contract (starts 2015) and Continuing (2014 omitted as 0)
fte_by_fund <- fte_by_fund |>
  complete(fiscal_year = 2013:2025, employee_group, fill = list(eg_fte = 0, other_funds_fte = 0, total_fte = 0, source_id = "factbook_fy27")) |>
  mutate(
    # Restore genuine NAs for State Classified E&G split FY21-24
    eg_fte = ifelse(employee_group == "State Classified" & fiscal_year %in% 2021:2024, NA_real_, eg_fte),
    other_funds_fte = ifelse(employee_group == "State Classified" & fiscal_year %in% 2021:2024, NA_real_, other_funds_fte)
  )

write_csv(fte_by_fund, file.path(proc_dir, "fte_by_fund_fy13_fy25.csv"))
message("  Saved fte_by_fund_fy13_fy25.csv (", nrow(fte_by_fund), " rows)")

# Parse FY25 Admin Professional FTE by Unit (Table 124, p.136 of FB27)
parse_ap_by_unit_p136 <- function(page_text) {
  lines <- strsplit(page_text, "\n")[[1]]
  tbl_lines <- grep("\\s+[0-9,]+\\.[0-9]\\s+[0-9,]+\\.[0-9]\\s+[0-9,]+\\.[0-9]\\s*$", lines, value = TRUE)
  map_dfr(tbl_lines, function(ln) {
    m <- regexec("^\\s*(.+?)\\s+([0-9,]+\\.[0-9])\\s+([0-9,]+\\.[0-9])\\s+([0-9,]+\\.[0-9])\\s*$", ln)
    parts <- regmatches(ln, m)[[1]]
    if (length(parts) != 5) return(tibble())
    tibble(
      unit = trimws(parts[2]),
      eg_fte = as.numeric(gsub(",", "", parts[3])),
      other_funds_fte = as.numeric(gsub(",", "", parts[4])),
      total_fte = as.numeric(gsub(",", "", parts[5]))
    )
  }) |>
    filter(unit != "Total FTE")
}

ap_unit_fy25 <- parse_ap_by_unit_p136(fb27_txt[136]) |>
  mutate(
    non_eg_share = other_funds_fte / total_fte,
    unit_category = case_when(
      unit %in% c("Warner College of Natural Resources", "Veterinary Medicine & Biomedical Sci",
                  "Walter Scott Jr College of Engr", "Agricultural Sciences",
                  "Health and Human Sciences", "Natural Sciences", "Liberal Arts",
                  "Business", "Libraries") ~ "Academic Colleges & Libraries",
      unit %in% c("Agric Sciences-Agric Experiment Station", "CSU Extension",
                  "Natural Resources-Colo State Forest Svc") ~ "State Agencies / Extension",
      unit %in% c("President's Office-Athletics", "President's Office-Athletic Compliance") ~ "Athletics & Compliance",
      grepl("^VPSA", unit) ~ "Student Affairs / Auxiliaries",
      TRUE ~ "Central Admin, VP Divisions & SPUR"
    ),
    cemml_research_flag = unit %in% c(
      "Warner College of Natural Resources",
      "Veterinary Medicine & Biomedical Sci",
      "Walter Scott Jr College of Engr",
      "Agricultural Sciences"
    ),
    source_id = "factbook_fy27"
  )

write_csv(ap_unit_fy25, file.path(proc_dir, "ap_fte_by_unit_fy25.csv"))
message("  Saved ap_fte_by_unit_fy25.csv (", nrow(ap_unit_fy25), " units; Total E&G AP=",
        round(sum(ap_unit_fy25$eg_fte), 1), ", Non-E&G AP=", round(sum(ap_unit_fy25$other_funds_fte), 1), ")")

# Also extract FB27 Table 123 (FY25 AP FTE by Detailed Fund)
ap_fund_detail_fy25 <- tribble(
  ~fund_group, ~fte_fy25, ~is_eg,
  "Education & General", 1392.6, TRUE,
  "Other Funds",         1159.2, FALSE,
  "Sponsored Programs",   871.2, FALSE,
  "Recharge Centers",     735.6, FALSE,
  "Auxiliaries",          439.4, FALSE
) |> mutate(share = fte_fy25 / sum(fte_fy25), source_id = "factbook_fy27")
write_csv(ap_fund_detail_fy25, file.path(proc_dir, "ap_fte_by_detailed_fund_fy25.csv"))

# ==============================================================================
# 3. CDHE BUDGET DATA BOOKS (FY16-FY27): E&G STUDENT FTE, TUITION, & E&G STAFF
# ==============================================================================
message("--- Parsing 3: CDHE Budget Data Books (Formats 20, 30, 100) ---")
bdb_files <- sort(list.files(file.path(raw_dir, "budgets"), pattern = "^FINAL_BDB_FY.*\\.pdf$", full.names = TRUE))

extract_last_nums <- function(line, k = 2) {
  # Extract trailing numeric tokens (incl optional commas, decimals, parens)
  toks <- regmatches(line, gregexpr("\\(?[0-9][0-9,]*(?:\\.[0-9]+)?\\)?", line))[[1]]
  if (length(toks) == 0) return(rep(NA_real_, k))
  vals <- parse_acct_num(tail(toks, k))
  if (length(vals) < k) vals <- c(rep(NA_real_, k - length(vals)), vals)
  vals
}

bdb_records <- map_dfr(bdb_files, function(f) {
  txt <- pdf_text(f)
  # Identify actual year and estimate year from cover page
  cov <- txt[1]
  act_fy <- as.integer(str_extract(str_extract(cov, "Actual Fiscal Year 20[0-9]{2}"), "20[0-9]{2}")) + 1L
  est_fy <- act_fy + 1L

  # Format 30 page
  p30 <- which(grepl("Format 30", txt) & grepl("STUDENT, FACULTY, AND STAFF DATA", txt))[1]
  has_est30 <- grepl("Estimate", txt[p30])
  l30 <- strsplit(txt[p30], "\n")[[1]]
  grab30 <- function(pat, two_cols = TRUE) {
    ln <- grep(pat, l30, value = TRUE)[1]
    if (is.na(ln)) return(c(NA_real_, NA_real_))
    if (two_cols && has_est30) {
      # Format 30 actual vs estimate columns: grab numbers after second line number
      extract_last_nums(ln, 2)
    } else {
      c(extract_last_nums(ln, 1)[1], NA_real_)
    }
  }
  res_ug <- grab30("Total Resident Undergraduate FTE")
  res_gr <- grab30("Resident Graduate FTE")
  res_tot <- grab30("Total Resident FTE")
  nr_ug <- grab30("Nonresident Undergraduate FTE")
  nr_gr <- grab30("Nonresident Graduate FTE")
  nr_tot <- grab30("Total Nonresident FTE")
  st_tot <- grab30("Total FTE Students")
  cost_per_st <- grab30("Total E&G Cost Per FTE Student", two_cols = FALSE)
  fac_tot <- grab30("Faculty FTE Total", two_cols = FALSE)
  fac_ft <- grab30("FTE Full-time Faculty", two_cols = FALSE)
  fac_pt <- grab30("FTE Part-time Faculty", two_cols = FALSE)
  avg_comp_all <- grab30("All Faculty Combined", two_cols = FALSE)
  tot_eg_fte <- grab30("Total Faculty and Staff FTE", two_cols = FALSE)

  # Format 20 page (Tuition, FFS, COF, Scholarships, Total E&G Exp)
  p20 <- which(grepl("Format 20", txt) & grepl("INSTITUTION SUMMARY", txt))[1]
  l20 <- strsplit(txt[p20], "\n")[[1]]
  grab20_act <- function(pat) {
    ln <- grep(pat, l20, value = TRUE)[1]
    if (is.na(ln)) return(c(NA_real_, NA_real_, NA_real_, NA_real_))
    # Format 20 has: Ln_no | Act_FTE | Act_Dollars | Est_FTE | Est_Dollars (or 2 dollar cols)
    extract_last_nums(ln, 4)
  }
  eg_tot_line <- grep("TOTAL EDUCATION & GENERAL EXPENDITURES", l20, value = TRUE)[1]
  eg_tot_nums <- extract_last_nums(eg_tot_line, 4) # Act_FTE, Act_$, Est_FTE, Est_$
  sch_line <- grep("Scholarships & Fellowships", l20, value = TRUE)[1]
  sch_nums <- extract_last_nums(sch_line, 2) # Act_$, Est_$
  tuition_tot_line <- grep("^\\s*20\\s+Total Tuition", l20, value = TRUE)[1]
  tuition_nums <- extract_last_nums(tuition_tot_line, 2)
  res_ug_tuition_line <- grep("Subtotal Undergraduate Resident Tuition", l20, value = TRUE)[1]
  res_ug_t_nums <- extract_last_nums(res_ug_tuition_line, 2)
  nr_tuition_line <- grep("Non-Resident Tuition", l20, value = TRUE)[1]
  nr_t_nums <- extract_last_nums(nr_tuition_line, 2)
  ffs_line <- grep("FFS Contracts", l20, value = TRUE)[1]
  ffs_nums <- extract_last_nums(ffs_line, 2)
  cof_line <- grep('Undergraduate Resident Tuition "Stipend"', l20, value = TRUE)[1]
  cof_nums <- extract_last_nums(cof_line, 4) # Act_FTE, Act_$, Est_FTE, Est_$

  # Return Actual row (and Estimate row for FY27 from latest book)
  act_row <- tibble(
    fiscal_year = act_fy,
    status = "Actual",
    source_file = basename(f),
    res_ug_fte = res_ug[1], res_grad_fte = res_gr[1], resident_fte = res_tot[1],
    nr_ug_fte = nr_ug[1], nr_grad_fte = nr_gr[1], nonresident_fte = nr_tot[1],
    total_student_fte = st_tot[1],
    eg_cost_per_student_fte = cost_per_st[1],
    eg_faculty_fte = fac_tot[1], eg_faculty_ft = fac_ft[1], eg_faculty_pt = fac_pt[1],
    eg_faculty_avg_comp = avg_comp_all[1],
    eg_total_staff_faculty_fte = tot_eg_fte[1],
    eg_nonfaculty_staff_fte = tot_eg_fte[1] - fac_tot[1],
    eg_total_exp = eg_tot_nums[2],
    eg_scholarships = sch_nums[1],
    eg_total_tuition = tuition_nums[1],
    eg_res_ug_tuition = res_ug_t_nums[1],
    eg_nr_tuition = nr_t_nums[1],
    eg_ffs_contracts = ffs_nums[1],
    eg_cof_stipend = cof_nums[2]
  )
  if (est_fy == 2027L) {
    est_row <- tibble(
      fiscal_year = est_fy,
      status = "Estimate",
      source_file = basename(f),
      res_ug_fte = res_ug[2], res_grad_fte = res_gr[2], resident_fte = res_tot[2],
      nr_ug_fte = nr_ug[2], nr_grad_fte = nr_gr[2], nonresident_fte = nr_tot[2],
      total_student_fte = st_tot[2],
      eg_cost_per_student_fte = NA_real_,
      eg_faculty_fte = NA_real_, eg_faculty_ft = NA_real_, eg_faculty_pt = NA_real_,
      eg_faculty_avg_comp = NA_real_,
      eg_total_staff_faculty_fte = eg_tot_nums[3],
      eg_nonfaculty_staff_fte = NA_real_,
      eg_total_exp = eg_tot_nums[4],
      eg_scholarships = sch_nums[2],
      eg_total_tuition = tuition_nums[2],
      eg_res_ug_tuition = res_ug_t_nums[2],
      eg_nr_tuition = nr_t_nums[2],
      eg_ffs_contracts = ffs_nums[2],
      eg_cof_stipend = cof_nums[4]
    )
    return(bind_rows(act_row, est_row))
  }
  act_row
}) |>
  arrange(fiscal_year)

# Note: FINAL_BDB_FY17-18 Format 30 also has FY15-16 Actual on some formats or check if FY16 is in FY16-17.
# Let's check whether all 11 years FY17-FY27 parsed cleanly:
write_csv(bdb_records, file.path(proc_dir, "bdb_eg_summary_fy17_fy27.csv"))
message("  Saved bdb_eg_summary_fy17_fy27.csv (", nrow(bdb_records), " fiscal years)")

# ==============================================================================
# 4. FACT BOOK FALL CENSUS ENROLLMENT (2015-2026) & FALL 2026 RI BREAKDOWN
# ==============================================================================
message("--- Parsing 4: Fact Book & BOG Fall Census Enrollment ---")
# Table 1 of FB27 (p.5): History since 1912 -> extract 2015..2026 Total Headcount
fb_p5_lines <- strsplit(fb27_txt[5], "\n")[[1]]
all_yr_pairs <- unlist(regmatches(fb_p5_lines, gregexpr("(201[5-9]|202[0-6])\\s+[0-9,]+", fb_p5_lines)))
enroll_hist <- tibble(raw = all_yr_pairs) |>
  separate(raw, into = c("fall_year", "headcount"), sep = "\\s+", convert = TRUE) |>
  mutate(headcount = as.numeric(gsub(",", "", headcount))) |>
  arrange(fall_year)

# Table 2 of FB27 (p.6): RI vs Non-RI, UG vs Grad (2019-2026)
# Plus Fall 2026 Residency / International breakdown from Fall-Budget-Forum-Slides-10.14.26.pdf Slides 4-6
# and Fall 2026 BOG Report (2026-09-24_BOG_Fall_Report_Retention.pdf)
fall_census_detail <- tribble(
  ~fall_year, ~ri_total, ~ri_credit_hours, ~ri_fte, ~ug_total_all, ~grad_total_all, ~prof_dvm_all, ~learning_innov, ~total_all_campus,
  2019L, 28864, NA_real_, NA_real_, 26559, 6846, 590, 4112, 34166,
  2020L, 27835, NA_real_, NA_real_, 25186, 6859, 601, 4325, 32765,
  2021L, 27954, NA_real_, NA_real_, 25362, 6804, 608, 4328, 32908,
  2022L, 27956, NA_real_, NA_real_, 26062, 6688, 609, 4331, 33455,
  2023L, 27833, NA_real_, NA_real_, 26168, 6775, 609, 4563, 33648,
  2024L, 28208, NA_real_, NA_real_, 26500, 7002, 607, 4787, 34218,
  2025L, 28194, 364314 / (1 - 0.026), 12488 / (1 - 0.025), 26839, 6862, 609, 4994, 34412,
  2026L, 27491, 364314,               12488,               26175, 6584, 627, 4769, 33461
) |>
  left_join(enroll_hist, by = "fall_year") |>
  mutate(source_id = "factbook_fy27 + forum_oct2026")
write_csv(fall_census_detail, file.path(proc_dir, "fall_census_enrollment_2019_2026.csv"))

# ==============================================================================
# 5. OPERATING BUDGET SUMMARIES (FY24-27) & COLLEGE/DIVISION E&G OBS (FY17-26)
# ==============================================================================
message("--- Parsing 5: Operating Budget Summaries & College/Division OBS ---")
obs_files <- sprintf(file.path(raw_dir, "budgets/FY%d_Operating_Budget_Summary.pdf"), 24:27)
obs_summary <- map_dfr(obs_files, function(f) {
  yr <- as.integer(paste0("20", str_extract(basename(f), "(?<=FY)[0-9]{2}")))
  txt <- pdf_text(f)
  p4 <- strsplit(txt[4], "\n")[[1]]
  grab_obs <- function(pat) {
    ln <- grep(pat, p4, value = TRUE)[1]
    if (is.na(ln)) return(NA_real_)
    tail(extract_last_nums(ln, 1), 1)
  }
  p3 <- strsplit(txt[3], "\n")[[1]]
  sa_ln <- grep("^\\s*State Appropriated", p3, value = TRUE)[1]
  sa_tot <- if (!is.na(sa_ln)) tail(extract_last_nums(sa_ln, 1), 1) else NA_real_
  tu_ln <- grep("^\\s*Total University", p3, value = TRUE)[1]
  tu_tot <- if (!is.na(tu_ln)) tail(extract_last_nums(tu_ln, 1), 1) else NA_real_

  tibble(
    fiscal_year = yr,
    state_ffs = grab_obs("State Fee For Service"),
    state_cof = grab_obs("College Opportunity Fund"),
    state_total = state_ffs + state_cof,
    tuition_state_approp = grab_obs("^\\s*Tuition\\s+"),
    idcr = grab_obs("Indirect Cost Recoveries"),
    course_fees = grab_obs("Course Fees"),
    state_approp_total = sa_tot,
    total_university_budget = tu_tot,
    source_id = paste0("obs_fy", substr(yr, 3, 4))
  )
})
write_csv(obs_summary, file.path(proc_dir, "obs_state_approp_fy24_fy27.csv"))
message("  Saved obs_state_approp_fy24_fy27.csv (", nrow(obs_summary), " years)")

# Parse College/Division E&G Operating Budget Summary (FY15-FY26)
col_obs_files <- sprintf(file.path(raw_dir, "budgets/FY%d_College_Division_OBS.pdf"), 15:26)
parse_col_obs <- function(f) {
  yr <- as.integer(paste0("20", str_extract(basename(f), "(?<=FY)[0-9]{2}")))
  txt <- paste(pdf_text(f), collapse = "\n")
  lines <- strsplit(txt, "\n")[[1]]

  # Extract key section subtotals and specific lines (EG Resident Instruction column + Total Operating column)
  find_line <- function(pat) {
    hits <- grep(pat, lines, value = TRUE)
    if (length(hits) == 0) return(NA_character_)
    hits[1]
  }
  # Helper: get first large dollar figure (E&G Sub-Total) and last large dollar figure (Total Operating)
  # Note: footnote superscripts (e.g., "1", "2", "10") appear as small integers; ignore numbers < 1000 unless 0
  get_eg_and_total <- function(pat) {
    ln <- find_line(pat)
    if (is.na(ln)) return(c(NA_real_, NA_real_))
    # Match formatted numbers with commas (or parens) e.g. 17,081,870 or (9,197,951) or 100.0%
    toks <- regmatches(ln, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?", ln))[[1]]
    if (length(toks) == 0) return(c(NA_real_, NA_real_))
    vals <- parse_acct_num(toks)
    c(vals[1], tail(vals, 1))
  }

  # Section subtotals appear in fixed order:
  # 1 Colleges, 2 PVM & Agencies, 3 Academic Support, 4 President's Division,
  # 5 Student Support, 6 Support Division, 7 Central Budgets
  # Note: in FY19-FY20 some Subtotal lines wrap numbers onto the next line due to footnote superscripts.
  sub_idx <- grep("^\\s*Subtotal\\b", lines)
  get_sub <- function(idx) {
    if (idx > length(sub_idx)) return(c(NA_real_, NA_real_))
    i <- sub_idx[idx]
    ln <- lines[i]
    toks <- regmatches(ln, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?", ln))[[1]]
    if (length(toks) == 0 && i < length(lines)) {
      ln <- lines[i + 1L]
      toks <- regmatches(ln, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?", ln))[[1]]
    }
    if (length(toks) == 0) return(c(NA_real_, NA_real_))
    vals <- parse_acct_num(toks)
    c(vals[1], tail(vals, 1))
  }

  s_col  <- get_sub(1)
  s_pvm  <- get_sub(2)
  s_acad <- get_sub(3)
  s_pres <- get_sub(4)
  s_stud <- get_sub(5)
  s_supp <- get_sub(6)
  s_cent <- get_sub(7)
  gtot   <- get_eg_and_total("Grand Total")

  b2_ath <- get_eg_and_total("B2 Athletics|\\bAthletics\\b")
  xa_debt <- get_eg_and_total("XA\\s+Debt Service")
  xa_fringe <- get_eg_and_total("XA\\s+Employee Fringe Benefits")
  # Capture P1 Enrollment and Access institutional aid (col 2) + XA Scholarship / Guaranteed Renewals
  p1_idx <- grep("Enrollment and Access|Enrollment & Access", lines)[1]
  p1_schol <- 0
  if (!is.na(p1_idx)) {
    p1_ln <- lines[p1_idx]
    toks <- regmatches(p1_ln, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", p1_ln))[[1]]
    if (length(toks) == 0 && p1_idx < length(lines)) {
      p1_ln <- lines[p1_idx + 1L]
      toks <- regmatches(p1_ln, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", p1_ln))[[1]]
    }
    vals <- parse_acct_num(toks)
    # In FY19+, col 1 is Resident Instruction, col 2 is Other Operating (Scholarships/Aid), col 3 is Total
    if (yr >= 2019 && length(vals) >= 3) p1_schol <- vals[2]
  }
  xa_tier_aid <- if (yr <= 2018L) get_eg_and_total("Scholarship & Grants|Guaranteed Renewals") else c(0, 0)
  if (yr <= 2018L && is.na(xa_tier_aid[1])) {
    t_idx <- grep("Tier I & II", lines)
    if (length(t_idx) > 0) {
      blk <- paste(lines[t_idx[1]:min(length(lines), t_idx[1] + 2)], collapse = " ")
      toks <- regmatches(blk, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", blk))[[1]]
      if (length(toks) > 0) xa_tier_aid <- c(parse_acct_num(toks[1]), parse_acct_num(tail(toks, 1)))
    }
  }
  xa_schol_exp <- get_eg_and_total("XA\\s+Scholarship Expense")
  inst_aid_budget_eg <- sum(c(p1_schol, ifelse(is.na(xa_tier_aid[1]), 0, xa_tier_aid[1]),
                              ifelse(is.na(xa_schol_exp[1]), 0, xa_schol_exp[1])), na.rm = TRUE)
  foot_schol <- get_eg_and_total("^\\s*Scholarships\\s+[0-9,]+|Scholarships \\(Total")

  # Reconcile Academic Support ex-Institutional Aid (because in FY19, $41.64M of Tier I/II aid moved from XA Central to P1 Academic Support!)
  acad_support_ex_aid <- s_acad[2] - p1_schol

  tibble(
    fiscal_year = yr,
    colleges_total = s_col[2],
    pvm_agencies_total = s_pvm[2],
    academic_support_total = s_acad[2],
    academic_support_ex_aid = acad_support_ex_aid,
    presidents_div_total = s_pres[2],
    student_support_total = s_stud[2],
    support_div_total = s_supp[2],
    central_budgets_total = s_cent[2],
    grand_total = gtot[2],
    b2_athletics_eg = b2_ath[1],
    xa_debt_service = xa_debt[1],
    xa_fringe_benefits = xa_fringe[1],
    p1_enrollment_aid = p1_schol,
    inst_aid_budget_eg = inst_aid_budget_eg,
    other_ops_scholarships = foot_schol[1],
    source_id = paste0("col_obs_fy", substr(yr, 3, 4))
  )
}

eg_div_budgets <- map_dfr(col_obs_files, parse_col_obs)
write_csv(eg_div_budgets, file.path(proc_dir, "eg_division_budgets_fy17_fy26.csv"))
message("  Saved eg_division_budgets_fy17_fy26.csv (", nrow(eg_div_budgets), " years)")

# ==============================================================================
# 6. CSU SYSTEM AUDITED FINANCIAL STATEMENTS (FY15-FY25)
# ==============================================================================
message("--- Parsing 6: CSU System Audited Financial Statements (FY15-FY25) ---")
audit_rows <- map_dfr(2015:2025, function(yr) {
  txt <- pdf_text(file.path(raw_dir, sprintf("audits/finstmt%d.pdf", yr)))

  # A. Debt from MD&A "Summary of Debt" (in thousands)
  p_debt <- which(grepl("Summary of Debt", txt))[1]
  d_lines <- strsplit(txt[p_debt], "\n")[[1]]
  d_idx <- grep("Summary of Debt", d_lines)[1]
  d_blk <- d_lines[d_idx:min(length(d_lines), d_idx + 14)]
  # Total debt line contains "Total" or starts with "$" near bottom of table
  tot_ln <- grep("Total.*Debt|^\\s*\\$\\s+[0-9,]+", d_blk, value = TRUE)
  tot_ln <- tail(tot_ln, 1)
  debt_vals <- parse_acct_num(regmatches(tot_ln, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", tot_ln))[[1]])
  # First column is always the current audit fiscal year (in thousands)
  sys_total_debt_k <- debt_vals[1]

  # B. SRECNP (in thousands): Net Tuition, Scholarship Allowance, State FFS, Grants & Contracts, Auxiliaries
  p_sr <- which(grepl("Statements of Revenues, Expenses", txt, ignore.case = TRUE) &
                  grepl("Student tuition and fees", txt, ignore.case = TRUE))[1]
  sr_txt <- paste(txt[p_sr:(p_sr + 1)], collapse = "\n")
  sr_lines <- strsplit(sr_txt, "\n")[[1]]

  # Extract tuition block strictly between "Student tuition and fees" and "State fee for service"
  tu_idx <- grep("^\\s*Student tuition and fees", sr_lines)[1]
  ffs_idx <- grep("^\\s*State fee for service", sr_lines)[1]
  tu_blk <- paste(sr_lines[tu_idx:(ffs_idx - 1L)], collapse = " ")
  sch_allow_match <- regmatches(tu_blk, regexec("allowances\\s+of\\s+\\$([0-9,]+)", tu_blk, ignore.case = TRUE))[[1]]
  sch_allow_k <- if (length(sch_allow_match) >= 2) parse_acct_num(sch_allow_match[2]) else NA_real_

  # Strip everything up to the LAST closing parenthesis before the dollar amount(s)
  after_paren <- sub("^.*\\)", "", tu_blk)
  net_tu_nums <- parse_acct_num(regmatches(after_paren, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", after_paren))[[1]])
  net_tuition_k <- net_tu_nums[1]

  grab_srecnp <- function(pat) {
    idx <- grep(pat, sr_lines, ignore.case = TRUE)[1]
    if (is.na(idx)) return(NA_real_)
    blk <- paste(sr_lines[idx:min(length(sr_lines), idx + 3)], collapse = " ")
    # Take numbers on the line that closes the item (or first line with column numbers)
    ln <- sr_lines[idx]
    nums <- parse_acct_num(regmatches(ln, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", ln))[[1]])
    if (length(nums) == 0) {
      ln <- sr_lines[idx + 1]
      nums <- parse_acct_num(regmatches(ln, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", ln))[[1]])
    }
    nums[1]
  }

  ffs_k <- grab_srecnp("^\\s*State fee for service")
  # Grants & contracts: multiline "(including ...)" -> grab after closing paren
  gr_idx <- grep("^\\s*Grants and contracts", sr_lines)[1]
  gr_blk <- paste(sr_lines[gr_idx:min(length(sr_lines), gr_idx + 3)], collapse = " ")
  gr_after <- sub("^.*\\)", "", gr_blk)
  grants_k <- parse_acct_num(regmatches(gr_after, gregexpr("[0-9]{1,3}(?:,[0-9]{3})+", gr_after))[[1]])[1]

  # Total operating revenues & expenses & net operating income (loss)
  tot_op_rev_k <- grab_srecnp("^\\s*Total operating revenues")
  tot_op_exp_k <- grab_srecnp("^\\s*Total operating expenses")
  pell_k <- grab_srecnp("Pell grants")
  state_approps_nonop_k <- grab_srecnp("State appropriations") # if any

  tibble(
    fiscal_year = yr,
    system_net_tuition_m = net_tuition_k / 1000,
    system_schol_allowance_m = sch_allow_k / 1000,
    system_gross_tuition_m = (net_tuition_k + sch_allow_k) / 1000,
    system_tuition_discount_rate = sch_allow_k / (net_tuition_k + sch_allow_k),
    system_ffs_m = ffs_k / 1000,
    system_grants_contracts_m = grants_k / 1000,
    system_total_op_rev_m = tot_op_rev_k / 1000,
    system_total_op_exp_m = tot_op_exp_k / 1000,
    system_total_debt_m = sys_total_debt_k / 1000,
    source_id = paste0("audit_fy", substr(yr, 3, 4))
  )
})
write_csv(audit_rows, file.path(proc_dir, "audits_system_fy15_fy25.csv"))
message("  Saved audits_system_fy15_fy25.csv (", nrow(audit_rows), " years)")

# ==============================================================================
# 7. COLORADO OSA NCAA AUP REPORTS (CSU FY19-FY25 & CU BOULDER FY25)
# ==============================================================================
message("--- Parsing 7: Colorado OSA NCAA AUP Athletics Reports ---")
parse_csu_ncaa <- function(yr) {
  f <- file.path(raw_dir, sprintf("athletics/csu_ncaa_aup_fy%02d.pdf", yr - 2000L))
  txt <- pdf_text(f)
  p_st <- which(grepl("STATEMENT OF REVENUES AND EXPENSES", txt, ignore.case = TRUE) &
                  grepl("Ticket Sales", txt, ignore.case = TRUE))
  p_st <- p_st[length(p_st)]
  lines <- strsplit(txt[p_st], "\n")[[1]]

  grab_total <- function(pat, idx_range = seq_along(lines)) {
    sub_l <- lines[idx_range]
    i <- grep(pat, sub_l, ignore.case = TRUE)[1]
    if (is.na(i)) return(0)
    ln <- sub_l[i]
    # Check if line contains at least a dollar figure or dash placeholder (not a wrapped label-only line)
    has_cols <- grepl("\\$|\\s-\\s|[0-9]{2,}", ln)
    toks <- regmatches(ln, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?|\\b[0-9]{3,}\\b", ln))[[1]]
    if (!has_cols && length(toks) == 0 && i < length(sub_l)) {
      ln <- sub_l[i + 1]
      toks <- regmatches(ln, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?|\\b[0-9]{3,}\\b", ln))[[1]]
    }
    # Handle multiline items where numbers sit on line i+1 even with text on line i (e.g. "paid by the University...")
    if (length(toks) == 0 && !grepl("\\s-\\s*$", ln) && i < length(sub_l)) {
      ln2 <- sub_l[i + 1]
      if (!grepl("^[A-Za-z]{4,}.*[0-9]{3}", trimws(ln2)) || grepl("paid by|Related Entities|Rentals|Bonuses|Third-Party|Party", ln2, ignore.case = TRUE)) {
        toks <- regmatches(ln2, gregexpr("\\(?[0-9]{1,3}(?:,[0-9]{3})+\\)?|\\b[0-9]{3,}\\b", ln2))[[1]]
      }
    }
    if (length(toks) == 0) return(0)
    parse_acct_num(tail(toks, 1))
  }

  rev_end <- grep("Total Revenues", lines, ignore.case = TRUE)[1]
  exp_start <- rev_end + 1L
  rev_idx <- 1:rev_end
  exp_idx <- exp_start:length(lines)

  # Debt Note 5
  p_debt <- which(grepl("LONG-TERM OBLIGATIONS", txt, ignore.case = TRUE))[1]
  d_txt <- paste(txt[p_debt:min(length(txt), p_debt + 1)], collapse = " ")
  m_debt <- regmatches(d_txt, regexec("outstanding balance of \\$([0-9,]+).*?University.*?\\$([0-9,]+)", d_txt))[[1]]
  ath_debt <- if (length(m_debt) >= 3) parse_acct_num(m_debt[2]) else NA_real_
  uni_debt <- if (length(m_debt) >= 3) parse_acct_num(m_debt[3]) else NA_real_

  tibble(
    fiscal_year = yr,
    ticket_sales = grab_total("Ticket Sales", rev_idx),
    student_fees = grab_total("Student Fees", rev_idx),
    guarantees_rev = grab_total("^\\s*Guarantees", rev_idx),
    contributions = grab_total("^\\s*Contributions", rev_idx),
    direct_inst_support = grab_total("Direct Institutional Support", rev_idx),
    indirect_inst_support = grab_total("Indirect Institutional Support", rev_idx),
    ncaa_dist = grab_total("Total NCAA Distributions|NCAA Distributions", rev_idx),
    conf_dist = grab_total("Conference Distributions", rev_idx),
    media_rights = grab_total("Media Rights", rev_idx),
    concessions_parking = grab_total("Programs, Concessions", rev_idx),
    royalties_sponsorships = grab_total("Royalties, Licensing", rev_idx),
    total_revenues = grab_total("Total Revenues", rev_idx),
    athletic_student_aid = grab_total("Athletic Student Aid", exp_idx),
    coaching_comp = grab_total("Coaching Salaries", exp_idx) + grab_total("Coaching Compensation Paid by 3rd", exp_idx),
    support_staff_comp = grab_total("Support Staff/Administrative", exp_idx),
    facilities_debt_service = grab_total("Athletic Facilities, Debt Service", exp_idx),
    direct_facilities_maint = grab_total("Direct Facilities, Maintenance", exp_idx),
    equipment_uniforms = grab_total("Sports Equipment, Uniforms", exp_idx),
    game_expenses = grab_total("^\\s*Game Expenses", exp_idx),
    team_travel = grab_total("^\\s*Team Travel", exp_idx),
    indirect_inst_support_exp = grab_total("Indirect Institutional Support", exp_idx),
    total_expenses = grab_total("Total Operating Expenses", exp_idx),
    excess_deficit = grab_total("Excess \\(Deficit\\)", exp_idx),
    athletics_debt = ath_debt,
    university_debt = uni_debt,
    source_id = paste0("ncaa_csu_fy", substr(yr, 3, 4))
  )
}

athletics_csu <- map_dfr(2019:2025, parse_csu_ncaa) |>
  mutate(
    inst_plus_fees = direct_inst_support + indirect_inst_support + student_fees,
    self_generated_rev = total_revenues - inst_plus_fees,
    self_generated_share = self_generated_rev / total_revenues,
    inst_support_share = inst_plus_fees / total_revenues,
    net_cash_drag_est = inst_plus_fees - athletic_student_aid
  )
write_csv(athletics_csu, file.path(proc_dir, "athletics_ncaa_csu_fy19_fy25.csv"))
message("  Saved athletics_ncaa_csu_fy19_fy25.csv (", nrow(athletics_csu), " years)")

# ==============================================================================
# 8. FY27 & FY28 EXACT BRIDGE TABLES (VERIFIED FROM MAY 13 / APR 13 SLIDES & OCT 7 MEMO)
# ==============================================================================
message("--- Building 8: FY27 Actual Bridge, FY27 FTE Cuts, & FY28 Scenarios ---")
# Transcribed directly from verified raster images Campus-V4-5-13-2026_a-1.pdf Slides 5 & 6
fy27_v4_bridge <- tribble(
  ~section, ~line_item, ~amount_m, ~notes, ~source_citation,
  "New Resources", "Undergraduate Enrollment FTE Change", -7.834, "Declining continuing UG headcount", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "Graduate Enrollment FTE Change", -4.846, "Lower grad enrollment", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "UG Rate Increase (Res 3.5% / NR 4%)", 14.022, "$5.611M Res + $8.411M NR", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "Grad & PVM Rate Increases", 2.903, "Grad Res/NR 3% ($1.383M) + PVM ($1.520M)", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "Differential Tuition (3.5%)", 7.038, "Program differential tuition", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "State Funding Impact (FFS + SEP)", -0.858, "-$773k FFS - $85k SEP (essentially flat)", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "Board Prioritized + F&A Overhead", 1.435, "$883k BOG Yr2 + $552k F&A", "May 13 2026 V4 Deck, Slide 5",
  "New Resources", "Less: Institutional Financial Aid Growth", -5.029, "Offsetting tuition discount expansion", "May 13 2026 V4 Deck, Slide 5",
  "New Expenses", "Faculty/Staff Compensation & Fringe", -33.665, "3% Faculty/AP/GA pool, SC step, fringe", "May 13 2026 V4 Deck, Slide 6",
  "New Expenses", "Multi-Year Strategic Investments", -8.826, "Cyber, Business, Budget Model PIF", "May 13 2026 V4 Deck, Slide 6",
  "New Expenses", "Academic Incentive Funding", -8.120, "Differential tuition & tuition sharing", "May 13 2026 V4 Deck, Slide 6",
  "New Expenses", "Mandatory Cost Escalation", -8.678, "Bond payments, new facilities, insurance, utilities, library", "May 13 2026 V4 Deck, Slide 6",
  "New Expenses", "Quality Enhancements & BOG Mental Health", -1.814, "$931k startups/retentions + $883k mental health", "May 13 2026 V4 Deck, Slide 6",
  "Balancing Actions", "University Base Savings (Central)", 7.406, "Central permanent base reductions", "May 13 2026 V4 Deck, Slide 6",
  "Balancing Actions", "Campus Unit Reduction Target", 28.754, "Permanent cuts across Colleges/Divisions", "May 13 2026 V4 Deck, Slide 6",
  "Balancing Actions", "Vacant Position Reductions", 3.000, "Elimination of vacant lines", "May 13 2026 V4 Deck, Slide 6",
  "Balancing Actions", "One-Time Savings (EXPIRES IN FY28)", 15.112, "Non-recurring reserves/savings bridging FY27", "May 13 2026 V4 Deck, Slide 6"
)
write_csv(fy27_v4_bridge, file.path(proc_dir, "fy27_v4_budget_bridge.csv"))

# Transcribed from Campus-V4-5-13-2026_a-1.pdf Slide 10 (FY27 Permanent Personnel FTE Reductions)
fy27_fte_cuts <- tribble(
  ~unit_division, ~unit_type, ~state_classified, ~ttf, ~non_ttf, ~admin_pro, ~total_fte,
  "Ag Sciences - Academic", "College", 3.00, 3.45, 0, 0, 6.45,
  "Ag Sciences - Extension", "Agency/Ext", 0, 1.00, 0, 5.50, 6.50,
  "Business", "College", 0, 0, 0, 6.75, 6.75,
  "Engineering", "College", 0, 3.00, 4.00, 7.17, 14.17,
  "Liberal Arts", "College", 2.00, 4.00, 12.00, 0.59, 18.59,
  "Col. of Natural Sciences", "College", 3.00, 0, 0, 4.00, 7.00,
  "WCNR", "College", 1.50, 1.32, 0, 2.00, 4.82,
  "CVMBS & PVM", "College", 1.00, 4.75, 0, 9.10, 14.85,
  "CHHS", "College", 1.75, 0, 3.50, 4.63, 9.88,
  "Libraries", "College", 3.00, 0, 1.00, 1.00, 5.00,
  "Graduate School", "Academic Support", 0, 0, 0, 2.50, 2.50,
  "VP Research", "Academic Support", 0, 0, 0, 5.00, 5.00,
  "VP Faculty Affairs", "Academic Support", 0, 0, 0, 1.63, 1.63,
  "VP Undergraduate Affairs", "Academic Support", 0, 0, 0, 3.42, 3.42,
  "President's Office", "President's Div", 0, 0, 0, 1.32, 1.32,
  "Office of Inclusive Excellence", "President's Div", 0, 0, 0, 5.63, 5.63,
  "VP Equity, EO & Title IX", "President's Div", 0, 0, 0, 0.92, 0.92,
  "Athletics", "Student Support", 0, 0, 0, 4.40, 4.40,
  "VP Enrollment & Access", "Academic Support", 1.00, 0, 0, 2.00, 3.00,
  "Student Affairs", "Student Support", 1.00, 0, 0, 1.00, 2.00,
  "VP Information Technology", "Support Div", 0, 0, 0, 3.70, 3.70,
  "Human Resources", "Support Div", 2.00, 0, 0, 1.00, 3.00,
  "VP University Operations", "Support Div", 5.05, 0, 0, 5.30, 10.35,
  "University Advancement", "Support Div", 0, 0, 0, 1.00, 1.00,
  "VP Marketing & Comms", "Support Div", 0.95, 0, 0, 6.25, 7.20,
  "Provost Office", "Academic Support", 1.00, 0, 0, 1.56, 2.56,
  "VP Engagement", "Academic Support", 0, 0, 0, 1.21, 1.21,
  "VP Engagement - Extension", "Agency/Ext", 0, 0, 1.12, 1.26, 2.38,
  "Office of International Programs", "Academic Support", 0.35, 0, 1.00, 2.00, 3.35,
  "CO State Forest Service", "Agency/Ext", 2.00, 0, 0, 0, 2.00
) |> mutate(source_id = "forum_may2026")
write_csv(fy27_fte_cuts, file.path(proc_dir, "fy27_fte_cuts_by_unit.csv"))

# FY28 V1.0 Shortfall Bridge (sourced from Oct 7 2026 Memo & Oct 14 2026 Fall Forum Slides)
# Note: October 7 Memo states range $61.3M to $70.7M (midpoint $66.0M), ~$25M enrollment drop,
# plus $15.112M expiring FY27 one-time funds (May 13 V4 Slide 6 / Oct 14 Slide 13),
# leaving $21.2M to $30.6M net mandatory inflation / comp / state pressure (0%/1%/3% scenarios).
fy28_bridge <- tribble(
  ~step_order, ~driver, ~low_m, ~mid_m, ~high_m, ~type, ~source_citation,
  1L, "Enrollment & Net Tuition Mix Drop",        25.00, 25.00, 25.00, "Structural Driver", "Oct. 7, 2026 Presidential Memo; Oct. 14 Slides 4-6 (-2.5% RI, -9.7% Dom NR UG, -11.1% Intl)",
  2L, "Expiring FY27 One-Time Stopgap Funds",     15.11, 15.11, 15.11, "Structural Driver", "May 13, 2026 V4 Slide 6 ($15.112M); Oct. 14, 2026 Slide 13 ('One-time funds from FY27 expire in FY28')",
  3L, "Mandatory Costs, Comp & State Squeeze",    21.19, 25.89, 30.59, "Scenario Driver",   "Residual to Oct. 7 Memo total ($61.3M-$70.7M under 0%/1%/3% state & comp scenarios; OSPB -$1.5B state gap)",
  4L, "Projected FY28 Operating Gap",             61.30, 66.00, 70.70, "Total Gap",         "Oct. 7, 2026 Presidential Budget Message (V1.0 BOG review)"
)
write_csv(fy28_bridge, file.path(proc_dir, "fy28_shortfall_bridge.csv"))

# ==============================================================================
# 9. IPEDS 8-PEER BENCHMARKS (2015-2023)
# ==============================================================================
message("--- Parsing 9: IPEDS Peer Benchmarks ---")
ip_fin  <- read_csv(file.path(raw_dir, "peers", "ipeds_finance_2015_2023.csv"), show_col_types = FALSE)
ip_fte  <- read_csv(file.path(raw_dir, "peers", "ipeds_fte_2015_2023.csv"), show_col_types = FALSE)
ip_inst <- read_csv(file.path(raw_dir, "peers", "ipeds_sal_inst_2015_2023.csv"), show_col_types = FALSE)
ip_non  <- read_csv(file.path(raw_dir, "peers", "ipeds_sal_noninst_2015_2023.csv"), show_col_types = FALSE)
ip_sfr  <- read_csv(file.path(raw_dir, "peers", "ipeds_sfr_2015_2023.csv"), show_col_types = FALSE)

# Aggregate FTE across levels per unitid-year
# Note: in IPEDS Urban API, level_of_study == 99 is total (or sum across 1,2,3 if 99 missing)
fte_agg <- ip_fte |>
  filter(level_of_study == 99 | is.na(level_of_study)) |>
  group_by(unitid, year, inst_name_ref) |>
  summarise(
    ipeds_fte = {
      vals <- c(rep_fte, est_fte)
      if (all(is.na(vals))) NA_real_ else max(vals, na.rm = TRUE)
    },
    .groups = "drop"
  )
if (nrow(fte_agg) == 0) {
  fte_agg <- ip_fte |>
    group_by(unitid, year, inst_name_ref) |>
    summarise(ipeds_fte = sum(rep_fte, na.rm = TRUE), .groups = "drop")
}

# Aggregate instructional & non-instructional headcount
inst_agg <- ip_inst |>
  filter(contract_length == 99 | academic_rank == 99) |>
  # Inspect safely: prefer academic_rank == 99 & contract_length == 99 & sex == 99 if coded, else sum non-total slices
  group_by(unitid, year) |>
  summarise(
    has_tot = any(academic_rank == 99 & contract_length == 99 & sex == 99),
    inst_count_tot = ifelse(has_tot, max(instruc_staff_count[academic_rank == 99 & contract_length == 99 & sex == 99], na.rm = TRUE), NA_real_),
    inst_outlays_tot = ifelse(has_tot, max(salary_outlays[academic_rank == 99 & contract_length == 99 & sex == 99], na.rm = TRUE), NA_real_),
    .groups = "drop"
  )

# Fallback if rank/contract/sex total isn't coded 99: sum rank != 99 & contract_length != 99 & sex != 99
if (any(is.na(inst_agg$inst_count_tot))) {
  inst_sum <- ip_inst |>
    filter(academic_rank != 99, contract_length != 99, sex != 99) |>
    group_by(unitid, year) |>
    summarise(
      inst_count_sum = sum(instruc_staff_count, na.rm = TRUE),
      inst_outlays_sum = sum(salary_outlays, na.rm = TRUE),
      .groups = "drop"
    )
  inst_agg <- inst_agg |>
    left_join(inst_sum, by = c("unitid", "year")) |>
    mutate(
      inst_staff_count = coalesce(inst_count_tot, inst_count_sum),
      inst_salary_outlays = coalesce(inst_outlays_tot, inst_outlays_sum)
    ) |>
    select(unitid, year, inst_staff_count, inst_salary_outlays)
} else {
  inst_agg <- inst_agg |>
    select(unitid, year, inst_staff_count = inst_count_tot, inst_salary_outlays = inst_outlays_tot)
}

noninst_agg <- ip_non |>
  group_by(unitid, year) |>
  summarise(
    has_tot = any(staff_category == 99),
    noninst_staff_count = ifelse(
      has_tot,
      max(noninstruc_staff_count[staff_category == 99], na.rm = TRUE),
      sum(noninstruc_staff_count[staff_category != 99], na.rm = TRUE)
    ),
    noninst_salary_outlays = ifelse(
      has_tot,
      max(salary_outlays[staff_category == 99], na.rm = TRUE),
      sum(salary_outlays[staff_category != 99], na.rm = TRUE)
    ),
    .groups = "drop"
  ) |>
  select(-has_tot)

peer_panel <- ip_fin |>
  select(
    unitid, year, inst_name_ref,
    rev_tuition_fees_gross, rev_tuition_fees_net,
    rev_appropriations_state, rev_grants_contracts_state, rev_state_local_approps_grants,
    rev_grants_contracts_federal, rev_total_current,
    sch_allowances_tuition_fees,
    exp_instruc_total, exp_research_total, exp_inst_supp_total, exp_total_current,
    longterm_debt, est_fte, rep_fte, calc_fte
  ) |>
  left_join(fte_agg, by = c("unitid", "year", "inst_name_ref")) |>
  left_join(inst_agg, by = c("unitid", "year")) |>
  left_join(noninst_agg, by = c("unitid", "year")) |>
  left_join(ip_sfr |> select(unitid, year, student_faculty_ratio), by = c("unitid", "year")) |>
  mutate(
    fte_best = coalesce(ipeds_fte, rep_fte, est_fte, calc_fte),
    # Note: Colorado institutions report COF + FFS under rev_grants_contracts_state (included in rev_state_local_approps_grants),
    # whereas non-CO peers report state appropriations in rev_appropriations_state (also included in rev_state_local_approps_grants).
    # Combining rev_appropriations_state + rev_grants_contracts_state gives pure State Support (excluding local) without double-counting!
    state_funding_total = coalesce(rev_appropriations_state, 0) + coalesce(rev_grants_contracts_state, 0),
    tuition_share_rev = rev_tuition_fees_net / rev_total_current,
    tuition_discount_rate = sch_allowances_tuition_fees / rev_tuition_fees_gross,
    state_per_fte = state_funding_total / fte_best,
    debt_per_fte = longterm_debt / fte_best,
    noninst_to_inst_ratio = noninst_staff_count / inst_staff_count,
    research_share_exp = exp_research_total / exp_total_current
  )

write_csv(peer_panel, file.path(proc_dir, "peer_ipeds_panel_2015_2023.csv"))
message("  Saved peer_ipeds_panel_2015_2023.csv (", nrow(peer_panel), " unitid-year rows)")
message("=== 02_parse_and_clean.R COMPLETE ===")
