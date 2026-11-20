# CSU's FY28 budget gap (`csu_budget_context`)

An independent, source-linked look at Colorado State University's projected budget gap for fiscal year
2027–28: how large it is, where it comes from, and why the taxes Colorado voters approved in November 2026
do not close it.

**Live site: <https://matthewross07.github.io/csu_budget_context/>**

| Page | What it covers |
|---|---|
| [The budget gap](https://matthewross07.github.io/csu_budget_context/) | Scale of the gap, its causes, the new state taxes, and common explanations drawn to the same scale |
| [CSU in 2030: two scenarios](https://matthewross07.github.io/csu_budget_context/csu-2030.html) | A thought experiment on two responses. Built on stated assumptions; not a forecast |
| [Sources and corrections](https://matthewross07.github.io/csu_budget_context/sources.html) | Disclosure, every figure with its source document and page, and corrections to the first version |

## Disclosure

- **Author.** Matthew R. V. Ross, as an individual. This is not a publication of Colorado State University
  or the CSU System, and no one at the university reviewed it.
- **Use of AI.** AI coding agents did most of the work under the author's direction. The first version
  (November 19–20, 2026) was built with Google's Gemini in the Antigravity agent. On November 20, 2026,
  Anthropic's Claude re-read the source documents, checked each claim against them, removed what could not
  be supported, and rebuilt the site.
- **What "checked" means.** For each figure, the AI located the number in the source document, or computed
  it from numbers located there, and recorded the page. A person has not independently re-keyed every
  figure. The ledger exists so anyone can check any number quickly.
- **Limits.** The analysis uses public documents only. CSU has not published the line items behind its FY28
  projection, and that projection predates the election and the governor's budget.
- **No recommendation.** The site describes the problem. It does not propose or endorse a solution.

## What the site finds

- CSU projects a gap of $61.3M–$70.7M for FY28, after closing $54.3M for FY27.
- CSU attributes about $25M of the FY28 gap to enrollment. The losses are concentrated among nonresident and
  international students.
- From FY15 to FY25, nonresident tuition supplied 59% of the growth in tuition and state revenue on the
  general campus budget. Nonresident headcount has fallen 15.8% since fall 2024.
- None of the three fiscal measures passed in November 2026 dedicates money to university operating budgets.
- Executive payouts, athletics, central administration and debt service are each smaller than the gap.

Each of these is tied to a document and page in the
[figure ledger](https://matthewross07.github.io/csu_budget_context/sources.html#ledger).

## Repository layout

```text
docs/        The published site (GitHub Pages serves this folder)
site_v2/     Source for the published site
  data.py      Every figure, with source, page and kind; also the 2030 scenario assumptions
  build.py     Builds the three pages and figures.csv (Python 3, standard library only)
  style.css, tooltip.js
  README.md    Build and publish notes
data/        Source manifest and processed tables from the first version
src/, *.qmd, _quarto.yml, styles.scss, outputs/
             The first version's R + Quarto pipeline and outputs (superseded, see below)
DATA_GAPS.md Notes on source access from the first version
```

## Rebuild and publish

```bash
python3 site_v2/build.py
```

```bash
cp site_v2/index.html site_v2/csu-2030.html site_v2/sources.html site_v2/figures.csv docs/
```

Then commit and push. To change a scenario assumption, edit the `SCEN` dictionary in `site_v2/data.py` and
rebuild.

## Status of the first version

The R + Quarto pipeline in the repository root produced the site that was first published on November 19, 2026.
A re-audit found errors and unsupported claims in it; they are listed under
[What the re-audit changed](https://matthewross07.github.io/csu_budget_context/sources.html#corrections).
Its pages were removed from `docs/` on November 20, 2026 and remain in git history at commit `27bb3e8`.

The pipeline files are kept for reference. Do not treat their outputs, or `DATA_GAPS.md`, as verified.

**Do not run `quarto render`.** `_quarto.yml` still writes to `docs/` and would overwrite the published
site with the first version's pages.

## Corrections

Report errors at <https://github.com/matthewross07/csu_budget_context/issues>.
