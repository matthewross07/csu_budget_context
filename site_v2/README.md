# CSU budget site, version 2

A re-audited rebuild of the CSU FY28 budget site. Three static pages, no dependencies.

| File | What it is |
|---|---|
| `index.html` | Main page: scale of the gap, where it comes from, why new state taxes do not close it |
| `csu-2030.html` | Two illustrative scenarios for 2030. A thought experiment, clearly marked as such |
| `sources.html` | Disclosure, figure ledger, source documents, corrections to version 1 |
| `figures.csv` | The figure ledger as a spreadsheet |
| `data.py` | Every number, with its source document, page and kind. Also the scenario assumptions |
| `build.py` | Builds the pages from `data.py`. Standard-library Python 3 only |
| `style.css`, `tooltip.js` | Inlined into each page at build time |

## Rebuild

```bash
python3 site_v2/build.py
```

The build fails if the FY27 budget lines stop adding up (see the `assert` lines near the top of `build.py`).

## Change a scenario assumption

Edit the `SCEN` dictionary at the bottom of `data.py` and rebuild. The 2030 page recomputes.

## Publish

The pages are self-contained. `docs/` (the GitHub Pages folder) holds a copy of `index.html`,
`csu-2030.html`, `sources.html` and `figures.csv`. After a rebuild, copy those four files into `docs/`
again, then commit and push to publish.

## Status of version 1

On 2026-11-20 the version 1 pages, figures and PDF brief were removed from `docs/` and replaced with
this site. They remain in git history (commit 27bb3e8). The version 1 Quarto sources in the repository
root (`*.qmd`, `src/`, `_quarto.yml`) are still there but are superseded; `sources.html` lists what was
wrong with them.

**Do not run `quarto render`.** `_quarto.yml` still writes to `docs/` and would overwrite this site with
the version 1 pages.
