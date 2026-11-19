# run_all.R
# Master reproducible pipeline for CSU_finance

scripts <- c(
  "00_setup_theme.R",
  "01_fetch_sources.R",
  "02_parse_and_clean.R",
  "03_analysis_metrics.R",
  "04_make_figures.R",
  "05_verify_audit.R"
)

src_dir <- if (dir.exists("src")) "src" else "."
for (s in scripts) {
  message("\n>>> Running ", s, " ...")
  source(file.path(src_dir, s), local = new.env(parent = globalenv()))
}
message("\n>>> Full R pipeline complete.")
