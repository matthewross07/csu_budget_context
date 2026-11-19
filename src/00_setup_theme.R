# 00_setup_theme.R
# Shared packages, color palette, ggplot2 theme, and formatting helpers
# for CSU_finance (Colorado State University FY27-28 Budget Analysis)

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(patchwork)
  library(ggtext)
  library(gt)
  library(httr2)
  library(rvest)
  library(pdftools)
  library(jsonlite)
  library(janitor)
})

# Project root resolver (works from root or src/)
get_project_root <- function() {
  if (dir.exists("src") && dir.exists("data")) return(normalizePath("."))
  if (dir.exists("../src") && dir.exists("../data")) return(normalizePath(".."))
  stop("Cannot locate CSU_finance project root directory.")
}

PROJECT_ROOT <- get_project_root()

# Restrained CSU-inspired publication palette (colorblind-aware & high contrast)
csu_colors <- list(
  forest       = "#1E4D2B",  # Primary CSU deep green (E&G academic / core)
  forest_mid   = "#2E6F40",  # Secondary green (faculty / instructional)
  sage         = "#739E82",  # Soft green (non-E&G / research offset)
  slate        = "#2C3539",  # Dark charcoal-slate (primary text / benchmarks)
  steel        = "#3E6B89",  # Muted steel blue (self-generated / tuition / peers)
  gold         = "#9A7B1C",  # Darkened gold for accessible lines/text
  gold_fill    = "#D4C26A",  # Muted gold fill (one-time funds / fees)
  rust         = "#C04B35",  # Alert rust/coral (deficits, overshoot, debt burden)
  rust_light   = "#E4A093",  # Light coral (sensitivity range)
  gray_dark    = "#495057",  # Subtitles
  gray_mid     = "#6E7B85",  # Muted captions / neutral bars
  gray_light   = "#DCE2DF",  # Subtle rules / gridlines
  bg_cream     = "#FAFBF9",  # Subtle card/strip background
  white        = "#FFFFFF"
)

# Clean publication ggplot2 theme
theme_csu <- function(base_size = 11, grid_axis = "y") {
  th <- theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.background   = element_rect(fill = csu_colors$white, color = NA),
      panel.background  = element_rect(fill = csu_colors$white, color = NA),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.title = element_text(
        face = "bold", size = rel(1.25), color = csu_colors$slate,
        margin = margin(b = 4)
      ),
      plot.subtitle = element_markdown(
        size = rel(0.92), color = csu_colors$gray_dark, lineheight = 1.25,
        margin = margin(b = 12)
      ),
      plot.caption = element_text(
        size = rel(0.75), color = csu_colors$gray_mid, hjust = 0,
        lineheight = 1.15, margin = margin(t = 10)
      ),
      axis.title = element_text(size = rel(0.88), face = "bold", color = csu_colors$slate),
      axis.text  = element_text(size = rel(0.84), color = csu_colors$gray_dark),
      axis.line.x = element_line(color = csu_colors$gray_light, linewidth = 0.5),
      axis.ticks = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position  = "top",
      legend.justification = "left",
      legend.title     = element_text(size = rel(0.85), face = "bold", color = csu_colors$slate),
      legend.text      = element_text(size = rel(0.84), color = csu_colors$gray_dark),
      legend.key.size  = unit(0.9, "lines"),
      strip.background = element_rect(fill = csu_colors$bg_cream, color = NA),
      strip.text       = element_text(face = "bold", size = rel(0.92), color = csu_colors$slate,
                                      margin = margin(t = 5, b = 5)),
      plot.margin      = margin(14, 16, 12, 14)
    )

  if (grid_axis == "y") {
    th <- th + theme(
      panel.grid.major.y = element_line(color = "#ECEFEF", linewidth = 0.45),
      panel.grid.major.x = element_blank()
    )
  } else if (grid_axis == "x") {
    th <- th + theme(
      panel.grid.major.x = element_line(color = "#ECEFEF", linewidth = 0.45),
      panel.grid.major.y = element_blank(),
      axis.line.x = element_blank(),
      axis.line.y = element_line(color = csu_colors$gray_light, linewidth = 0.5)
    )
  } else {
    th <- th + theme(
      panel.grid.major = element_line(color = "#ECEFEF", linewidth = 0.4)
    )
  }
  th
}

# Currency and share formatters
fmt_m <- function(x, digits = 1) {
  paste0(ifelse(x < 0, "-$", "$"), formatC(abs(x), format = "f", digits = digits, big.mark = ","), "M")
}

fmt_pct <- function(x, digits = 1) {
  paste0(formatC(x * 100, format = "f", digits = digits), "%")
}

save_csu_fig <- function(plot, filename_stem, width = 10, height = 6.2, dpi = 300) {
  fig_dir <- file.path(PROJECT_ROOT, "outputs", "figures")
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(fig_dir, paste0(filename_stem, ".png"))
  svg_path <- file.path(fig_dir, paste0(filename_stem, ".svg"))
  ggsave(png_path, plot = plot, width = width, height = height, dpi = dpi, bg = "white")
  ggsave(svg_path, plot = plot, width = width, height = height, bg = "white")
  message("Saved figure: ", filename_stem, ".{png,svg}")
  invisible(list(png = png_path, svg = svg_path))
}
