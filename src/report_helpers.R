# src/report_helpers.R
# Shared data-loading, formatting, and table styling helpers for Quarto HTML & PDF pages.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(scales)
  library(gt)
  library(knitr)
  library(kableExtra)
})

load_proc <- function(filename) {
  read.csv(file.path("data/processed", filename), check.names = FALSE, stringsAsFactors = FALSE)
}

load_manifest <- function() {
  read.csv("data/sources_manifest.csv", check.names = FALSE, stringsAsFactors = FALSE)
}

fmt_m <- function(x, digits = 1, plus = FALSE) {
  out <- ifelse(
    is.na(x),
    "—",
    paste0(
      ifelse(x < 0, "-$", ifelse(plus & x > 0, "+$", "$")),
      formatC(abs(x), format = "f", digits = digits, big.mark = ","),
      "M"
    )
  )
  out
}

fmt_pct <- function(x, digits = 1, plus = FALSE) {
  val <- x * 100
  ifelse(
    is.na(x),
    "—",
    paste0(
      ifelse(plus & val > 0, "+", ""),
      formatC(val, format = "f", digits = digits),
      "%"
    )
  )
}

fmt_n <- function(x, digits = 0, plus = FALSE) {
  ifelse(
    is.na(x),
    "—",
    paste0(
      ifelse(plus & x > 0, "+", ifelse(x < 0, "-", "")),
      formatC(abs(x), format = "f", digits = digits, big.mark = ",")
    )
  )
}

csu_gt <- function(tbl, title = NULL, subtitle = NULL, source_note = NULL) {
  g <- gt::gt(tbl)
  if (!is.null(title) || !is.null(subtitle)) {
    g <- gt::tab_header(g, title = title, subtitle = subtitle)
  }
  if (!is.null(source_note)) {
    g <- gt::tab_source_note(g, source_note = source_note)
  }
  g |>
    gt::tab_options(
      table.width = gt::pct(100),
      heading.background.color = "#1E4D2B",
      heading.title.font.size = gt::px(15),
      heading.title.font.weight = "bold",
      heading.subtitle.font.size = gt::px(12),
      column_labels.background.color = "#EFF3F0",
      column_labels.font.weight = "bold",
      column_labels.font.size = gt::px(12),
      table.font.size = gt::px(13),
      data_row.padding = gt::px(6),
      source_notes.font.size = gt::px(11),
      table.border.top.color = "#1E4D2B",
      table.border.bottom.color = "#1E4D2B"
    )
}

csu_kable <- function(df, caption = NULL, col_names = names(df), align = NULL, scale_down = FALSE) {
  if (!is.null(caption)) {
    caption <- gsub("([&$%#_])", "\\\\\\1", caption)
  }
  opts <- c("striped", "hold_position")
  if (scale_down) opts <- c(opts, "scale_down")
  knitr::kable(
    df,
    format = "latex",
    booktabs = TRUE,
    caption = caption,
    col.names = col_names,
    align = align
  ) |>
    kableExtra::kable_styling(
      latex_options = opts,
      font_size = 9.0,
      stripe_color = "#F4F6F5"
    ) |>
    kableExtra::row_spec(0, bold = TRUE, background = "#EAEFEA")
}
