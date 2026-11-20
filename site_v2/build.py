#!/usr/bin/env python3
"""Build the v2 CSU budget site (index.html, sources.html, figures.csv).

Standard library only.  Run from anywhere:  python3 site_v2/build.py
All numbers come from data.py; nothing is typed into the page text by hand
except the wording.
"""
import csv
import html
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from data import F, SOURCES, BDB, HEADCOUNT, SCEN  # noqa: E402

AS_OF = "November 20, 2026"
REPO = "https://github.com/matthewross07/csu_budget_context"


# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
def v(key):
    return F[key][0]


def m(x, d=1):
    """Millions of dollars -> '$61.3M'."""
    return f"${x:,.{d}f}M"


def pct(x, d=0):
    return f"{x * 100:.{d}f}%"


def n(x, d=0):
    return f"{x:,.{d}f}"


def e(s):
    return html.escape(str(s), quote=True)


KIND_LABEL = {
    "csu": "CSU document",
    "state": "State document",
    "news": "News report",
    "calc": "Our arithmetic",
    "infer": "Our inference",
    "ext": "Outside report",
    "assume": "Our assumption",
    "scen": "Scenario result",
}


def tag(kind, text=None):
    return f'<span class="tag tag-{kind}">{e(text or KIND_LABEL[kind])}</span>'


def src(*ids):
    """Inline source links."""
    out = []
    for i in ids:
        s = SOURCES[i]
        out.append(f'<a href="{e(s["url"])}">{e(s["title"])}</a>')
    return "; ".join(out)


# ----------------------------------------------------------------------------
# derived numbers (all arithmetic on ledger values lives here)
# ----------------------------------------------------------------------------
gap_lo, gap_hi = v("gap_low"), v("gap_high")
rest_lo, rest_hi = gap_lo - v("enroll_gap"), gap_hi - v("enroll_gap")
resid_lo = rest_lo - v("fy27_onetime")
share_lo, share_hi = gap_lo / v("reducible"), gap_hi / v("reducible")
perm2_lo = v("fy27_permanent") + gap_lo
perm2_hi = v("fy27_permanent") + gap_hi
core_cost = v("v4_comp") + v("v4_mandatory")

assert abs(v("fy27_new_expenses") - (v("v4_comp") + v("v4_mandatory") + v("v4_strategic")
                                      + v("v4_incentive") + v("v4_other_exp"))) < 0.002
assert abs(v("fy27_gap") - (v("fy27_new_expenses") - v("fy27_net_new_resources"))) < 0.002
assert abs(v("fy27_gap") - (v("fy27_permanent") + v("fy27_onetime"))) < 0.002
assert abs(v("fy27_net_new_resources") - (v("v4_rates") + v("v4_enroll") + v("v4_state")
                                           + v("v4_other_rev") + v("v4_aid"))) < 0.002
assert abs(v("fy27_permanent") - (v("fy27_base_savings") + v("fy27_campus_cuts") + v("fy27_vacant"))) < 0.002


def bdb_row(fy):
    nr, res_ug, res_gr, ffs, cof, exp, res_fte, nr_fte = BDB[fy]
    return dict(nr=nr / 1e6, res=(res_ug + res_gr) / 1e6, state=(ffs + cof) / 1e6,
                exp=exp / 1e6, res_fte=res_fte, nr_fte=nr_fte, fte=res_fte + nr_fte)


S = {fy: bdb_row(fy) for fy in BDB}
a, p, z = S[2015], S[2025], S[2026]          # start, peak, latest
nr_growth_peak = p["nr"] - a["nr"]
res_growth_peak = p["res"] - a["res"]
state_growth_peak = p["state"] - a["state"]
nr_share_growth = nr_growth_peak / (nr_growth_peak + res_growth_peak + state_growth_peak)
cpi_15_25 = v("cpi_fy25") / v("cpi_fy15") - 1
cpi_15_26 = v("cpi_fy26") / v("cpi_fy15") - 1
cost_growth = v("cost_per_fte_fy26") / v("cost_per_fte_fy15") - 1
rev_per_15 = (a["nr"] + a["res"] + a["state"]) * 1e6 / a["fte"]
rev_per_26 = (z["nr"] + z["res"] + z["state"]) * 1e6 / z["fte"]
rev_per_growth = rev_per_26 / rev_per_15 - 1
nr_per_fte = z["nr"] * 1e6 / z["nr_fte"]
res_per_fte = z["res"] * 1e6 / z["res_fte"]
state_per_res = z["state"] * 1e6 / z["res_fte"]
state_share = z["state"] / z["exp"]
tuition_share = (z["nr"] + z["res"]) / z["exp"]
nr_share_rev = z["nr"] / z["exp"]
nr_head_drop = v("nr_head_2026") / v("nr_head_2024") - 1
one_pct_state = v("state_total_fy27") * 0.01
three_pct_state = v("state_total_fy27") * 0.03
one_pct_general = v("state_general_fy26") * 0.01
state_needed_lo = gap_lo / v("state_total_fy27")
state_needed_hi = gap_hi / v("state_total_fy27")
ath_support = v("ath_direct") + v("ath_indirect")
ath_support_fees_share = (ath_support + v("ath_fees")) / v("ath_rev")
payouts = v("payout_parsons") + v("payout_underwood") + v("payout_norvell")
ap_eg_share = v("ap_eg") / v("ap_total")
cdhe_fte_growth = v("cdhe_fte_fy26") / v("cdhe_fte_fy15") - 1
stu_growth_15_26 = z["fte"] / a["fte"] - 1
stu_growth_15_25 = p["fte"] / a["fte"] - 1
fb_fac_growth = v("fb_fac_fy25") / v("fb_fac_fy15") - 1
fb_staff_growth = v("fb_staff_fy25") / v("fb_staff_fy15") - 1


# ----------------------------------------------------------------------------
# chart builders
# ----------------------------------------------------------------------------
def hbars(rows, vmax, cls="", unit_fmt=m):
    """rows: list of dict(label, sub, value, value2=None, kind, color, tip)."""
    out = [f'<div class="hbars {cls}" role="list">']
    for r in rows:
        w = max(r["value"] / vmax * 100, 0.4)
        seg = (f'<span class="bar {r.get("color", "c-gray")}" style="width:{w:.2f}%"></span>')
        if r.get("value2"):
            w2 = (r["value2"] - r["value"]) / vmax * 100
            seg += f'<span class="bar range {r.get("color", "c-gray")}" style="width:{w2:.2f}%"></span>'
        val = r.get("value_label") or unit_fmt(r["value"])
        tip = e(r.get("tip") or f'{r["label"]}: {val}')
        sub = f'<span class="hb-sub">{r["sub"]}</span>' if r.get("sub") else ""
        out.append(
            f'<div class="hb-row" role="listitem" tabindex="0" data-tip="{tip}">'
            f'<div class="hb-label"><span class="hb-name">{r["label"]}</span>{sub}</div>'
            f'<div class="hb-track">{seg}<span class="hb-val">{e(val)}</span></div>'
            f'</div>')
    out.append("</div>")
    return "\n".join(out)


def segbar(parts, total_scale, label_inside=True):
    """Tall segmented bar. parts: list of dict(name, value, color, tip, pattern)."""
    out = ['<div class="segbar" role="img" aria-label="'
           + e("; ".join(f'{p_["name"]} {m(p_["value"])}' for p_ in parts)) + '">']
    for p_ in parts:
        w = p_["value"] / total_scale * 100
        inner = m(p_["value"]) if (label_inside and w > 9) else ""
        out.append(
            f'<span class="seg {p_["color"]}" style="width:{w:.2f}%" tabindex="0" '
            f'data-tip="{e(p_.get("tip") or p_["name"] + ": " + m(p_["value"]))}">'
            f'<span class="seg-val">{inner}</span></span>')
    out.append("</div>")
    return "\n".join(out)


def legend(items):
    return ('<ul class="legend">' + "".join(
        f'<li><span class="sw {c}"></span>{e(t)}</li>' for c, t in items) + "</ul>")


def table(headers, rows, caption=""):
    h = "".join(f"<th>{e(x)}</th>" for x in headers)
    b = "".join("<tr>" + "".join(
        (f"<th scope='row'>{c}</th>" if i == 0 else f"<td>{c}</td>") for i, c in enumerate(r)
    ) + "</tr>" for r in rows)
    cap = f"<caption>{e(caption)}</caption>" if caption else ""
    return f'<div class="tablewrap"><table>{cap}<thead><tr>{h}</tr></thead><tbody>{b}</tbody></table></div>'


def details_table(headers, rows, caption=""):
    return ('<details class="datatable"><summary>View these numbers as a table</summary>'
            + table(headers, rows, caption) + "</details>")


def linechart(W, H, compact=False):
    """Nonresident tuition vs resident tuition vs state support, FY15-FY26."""
    ml, mr, mt, mb = (44, 132, 16, 34) if not compact else (52, 16, 16, 34)
    pw, ph = W - ml - mr, H - mt - mb
    years = sorted(S)
    ymax = 300.0

    def X(fy):
        return ml + (fy - years[0]) / (years[-1] - years[0]) * pw

    def Y(val):
        return mt + ph - val / ymax * ph

    fs = 13 if not compact else 12
    o = [f'<svg viewBox="0 0 {W} {H}" class="linechart {"compact" if compact else "wide"}" '
         f'role="img" aria-label="Line chart: nonresident tuition, resident tuition and state support, '
         f'fiscal years 2015 to 2026. Values are in the table below.">']
    for g in (0, 100, 200, 300):
        o.append(f'<line class="grid" x1="{ml}" x2="{ml + pw}" y1="{Y(g):.1f}" y2="{Y(g):.1f}"/>')
        o.append(f'<text class="axis" x="{ml - 6}" y="{Y(g) + 4:.1f}" text-anchor="end" '
                 f'font-size="{fs}">{"$0" if g == 0 else f"${g}M"}</text>')
    step = 1 if not compact else 3
    for fy in years:
        if (fy - years[0]) % step == 0 or fy == years[-1]:
            if compact and fy == 2024:
                continue
            o.append(f'<text class="axis" x="{X(fy):.1f}" y="{H - 12}" text-anchor="middle" '
                     f'font-size="{fs}">FY{str(fy)[2:]}</text>')
    series = [("nr", "s1", "Nonresident tuition"), ("res", "s2", "Resident tuition"),
              ("state", "s3", "State support")]
    for key, cls, name in series:
        pts = " ".join(f"{X(fy):.1f},{Y(S[fy][key]):.1f}" for fy in years)
        o.append(f'<polyline class="line {cls}" points="{pts}"/>')
    for key, cls, name in series:
        last = years[-1]
        o.append(f'<circle class="dot {cls}" cx="{X(last):.1f}" cy="{Y(S[last][key]):.1f}" r="5"/>')
        if not compact:
            o.append(f'<text class="endlabel" x="{X(last) + 10:.1f}" y="{Y(S[last][key]) - 2:.1f}" '
                     f'font-size="13">{e(name)}</text>')
            o.append(f'<text class="endval" x="{X(last) + 10:.1f}" y="{Y(S[last][key]) + 14:.1f}" '
                     f'font-size="13">{m(S[last][key])}</text>')
    # peak marker on nonresident line
    o.append(f'<circle class="dot s1" cx="{X(2025):.1f}" cy="{Y(S[2025]["nr"]):.1f}" r="5"/>')
    o.append(f'<text class="note" x="{X(2025) - 8:.1f}" y="{Y(S[2025]["nr"]) - 10:.1f}" text-anchor="end" '
             f'font-size="{fs}">Peak: {m(S[2025]["nr"])} (FY25)</text>')
    o.append(f'<text class="note" x="{X(2021):.1f}" y="{Y(S[2021]["state"]) + 20:.1f}" text-anchor="middle" '
             f'font-size="{fs - 1}">FY21: pandemic year</text>')
    # hover columns
    half = pw / (len(years) - 1) / 2
    for fy in years:
        tip = (f'FY{str(fy)[2:]} — Nonresident tuition {m(S[fy]["nr"])} · '
               f'Resident tuition {m(S[fy]["res"])} · State support {m(S[fy]["state"])}')
        o.append(f'<rect class="hit" x="{X(fy) - half:.1f}" y="{mt}" width="{2 * half:.1f}" '
                 f'height="{ph}" tabindex="0" data-tip="{e(tip)}"/>')
    o.append("</svg>")
    return "\n".join(o)


# ----------------------------------------------------------------------------
# page pieces
# ----------------------------------------------------------------------------
CSS = open(os.path.join(HERE, "style.css")).read()
JS = open(os.path.join(HERE, "tooltip.js")).read()


def page(title, description, body, current):
    cur = ' aria-current="page"'
    nav = "".join(
        f'<a href="{href}"{cur if key == current else ""}>{label}</a>'
        for key, href, label in (("index", "index.html", "The budget gap"),
                                 ("2030", "csu-2030.html", "CSU in 2030: two scenarios"),
                                 ("sources", "sources.html", "Sources and corrections")))
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>{e(title)}</title>
<meta name="description" content="{e(description)}">
<style>
{CSS}
</style>
</head>
<body>
<div class="disclosure-bar" role="note">
  <strong>Independent analysis, not a CSU publication.</strong>
  Drafted with AI tools from public documents. Figures as of {AS_OF}.
  <a href="sources.html#disclosure">How this was made</a>
</div>
<header class="site">
  <div class="wrap">
    <span class="sitename">CSU budget, FY 2027&ndash;28</span>
    <nav aria-label="Pages">{nav}</nav>
  </div>
</header>
<main>
{body}
</main>
<footer class="site">
  <div class="wrap">
    <p><strong>Independent analysis by Matthew R. V. Ross. Not affiliated with, reviewed by, or speaking for
    Colorado State University or the CSU System.</strong> AI tools read the source documents and drafted this
    site; see <a href="sources.html#disclosure">how this was made</a>. Figures as of {AS_OF}; CSU's projection
    will change as the state budget develops.</p>
    <p>Found an error? <a href="{REPO}/issues">Report it</a>. Every number on this site is listed with its
    source in the <a href="sources.html#ledger">figure ledger</a>.</p>
  </div>
</footer>
<div id="tip" role="tooltip" hidden></div>
<script>
{JS}
</script>
</body>
</html>
"""


def figure(title, chart_html, note, tags, source_html, table_html=""):
    tg = " ".join(tag(k) for k in tags)
    return f"""<figure class="chart">
  <figcaption class="chart-title">{title}</figcaption>
  {chart_html}
  {table_html}
  <p class="chart-note">{note}</p>
  <p class="chart-src">{tg} <span class="srcline">Source: {source_html}</span></p>
</figure>"""


# ----------------------------------------------------------------------------
# INDEX
# ----------------------------------------------------------------------------
def build_index():
    b = []

    # ---------- hero ----------
    b.append(f"""
<section class="hero">
  <div class="wrap">
    <p class="eyebrow">Colorado State University, Fort Collins &middot; budget for July 2027 &ndash; June 2028</p>
    <h1>CSU projects a ${gap_lo:.0f}&ndash;{gap_hi:.0f} million gap next year. Here is where it comes from.</h1>
    <p class="lede">CSU cut ${v('fy27_gap'):.0f} million to balance this year's budget. Its first projection for
    next year shows a bigger gap, and it shows that gap in every scenario it modeled, including one with no
    raises. This page uses CSU's and the State of Colorado's own documents to show how large the problem is,
    what drives it, and why the taxes Colorado voters just approved do not fix it.</p>

    <div class="herofig">
      <div class="heronum">${gap_lo}M&ndash;${gap_hi}M</div>
      <div class="herocap">Projected gap in CSU's general-fund budget for fiscal year 2028,
      as CSU announced it on October 7, 2026. {tag('csu')}</div>
    </div>

    <aside class="disclosure" aria-label="About this page">
      <h2>Read this first</h2>
      <ul>
        <li><strong>Who made this.</strong> Matthew R. V. Ross, as an individual. It is not a CSU publication
        and has not been reviewed by the university.</li>
        <li><strong>How.</strong> AI tools read the public source documents, checked the numbers against them,
        and drafted the text and charts. The first version was built with Google's Gemini (Antigravity); this
        version is a re-audit and rewrite done with Anthropic's Claude on {AS_OF}.
        <a href="sources.html#corrections">What the re-audit changed</a>.</li>
        <li><strong>How to check it.</strong> Every figure carries a label saying whether it is printed in a
        CSU or state document, reported by a news outlet, our own arithmetic, or our inference.
        The <a href="sources.html#ledger">figure ledger</a> lists each one with its document and page.</li>
        <li><strong>What it cannot tell you.</strong> CSU has published the size of the gap but not the line
        items behind it. The projection was made before the election and before the governor's budget, and CSU
        says it will change. <a href="#unknowns">What we do not know</a>.</li>
      </ul>
      <p class="taglegend">Labels used on this page: {tag('csu')} {tag('state')} {tag('news')} {tag('calc')} {tag('infer')}</p>
    </aside>
  </div>
</section>
""")

    # ---------- 1 scale ----------
    scale_rows = [
        dict(label="This year (FY27)", sub="gap that was closed",
             value=v("fy27_gap"), color="c-gap-done",
             value_label=m(v("fy27_gap")),
             tip=f"FY27 gap closed: {m(v('fy27_gap'))} = {m(v('fy27_permanent'))} permanent cuts + {m(v('fy27_onetime'))} one-time money"),
        dict(label="Next year (FY28)", sub="projected, not yet closed",
             value=gap_lo, value2=gap_hi, color="c-gap",
             value_label=f"{m(gap_lo)}–{m(gap_hi)}",
             tip=f"FY28 projected gap: {m(gap_lo)} to {m(gap_hi)} depending on scenario"),
    ]
    chart1 = hbars(scale_rows, 75, cls="big")
    b.append(f"""
<section id="scale">
  <div class="wrap">
    <p class="secnum">1</p>
    <h2>How big is it?</h2>
    <p class="answer">Bigger than last year's, which already took {n(v('fy27_fte_cut'), 0)} permanent positions.</p>

    <div class="tiles">
      <div class="tile"><div class="tv">{m(gap_lo)}&ndash;{m(gap_hi)}</div>
        <div class="tl">Projected gap for FY28</div><div class="tt">{tag('csu')}</div></div>
      <div class="tile"><div class="tv">{m(v('fy27_gap'))}</div>
        <div class="tl">Gap closed for FY27: {m(v('fy27_permanent'))} in permanent cuts and
        {m(v('fy27_onetime'))} of one-time money</div><div class="tt">{tag('csu')}</div></div>
      <div class="tile"><div class="tv">{pct(share_lo)}&ndash;{pct(share_hi)}</div>
        <div class="tl">FY28 gap as a share of the {m(v('reducible'), 0)} CSU called its
        &ldquo;reducible&rdquo; budget</div><div class="tt">{tag('calc')}</div></div>
      <div class="tile"><div class="tv">{n(v('fy27_fte_cut'), 2)}</div>
        <div class="tl">Permanent positions (FTE) eliminated to balance FY27</div><div class="tt">{tag('csu')}</div></div>
    </div>

    {figure("Two budget gaps, back to back",
            chart1,
            f"The FY27 gap was closed with {m(v('fy27_permanent'))} of permanent cuts and {m(v('fy27_onetime'))} "
            f"of one-time money. The lighter end of the FY28 bar is the range across CSU's three scenarios.",
            ["csu", "calc"],
            src("forum_may13", "memo_oct7"),
            details_table(["Year", "Gap", "How it was or would be closed"],
                          [["FY27 (current year)", m(v("fy27_gap"), 3),
                            f"{m(v('fy27_permanent'), 3)} permanent; {m(v('fy27_onetime'), 3)} one-time"],
                           ["FY28 (projected)", f"{m(gap_lo)}–{m(gap_hi)}", "Not yet decided"]]))}

    <div class="points">
      <div class="point">
        <h3>No scenario avoids it</h3>
        <p>CSU modeled state funding rising 0%, 1% or 3%, each paired with a matching assumption for raises
        (0%, 1%, 3%). The gap is at least {m(gap_lo)} in all three. {tag('csu')}</p>
      </div>
      <div class="point">
        <h3>It is larger than any one college</h3>
        <p>The low end of the range exceeds the entire FY26 general-fund budget of the College of Liberal Arts
        ({m(v('la_budget'))}), the largest college budget at CSU. {tag('calc')}</p>
      </div>
      <div class="point">
        <h3>Two years, about a fifth of the base</h3>
        <p>If FY28 is closed with permanent cuts alone, CSU will have removed {m(perm2_lo, 0)}&ndash;{m(perm2_hi, 0)}
        in two years, or {pct(perm2_lo / v('reducible'))}&ndash;{pct(perm2_hi / v('reducible'))} of the
        {m(v('reducible'), 0)} it considered reducible. {tag('calc')}</p>
      </div>
    </div>
    <p class="fine">Sources: {src("memo_oct7", "forum_oct14", "forum_apr13", "colobs_fy26")}.
    &ldquo;General fund&rdquo; here means CSU's Education and General budget: tuition and state support, the
    money that pays for teaching and campus operations. It does not include research grants, housing, or
    other self-funded operations.</p>
  </div>
</section>
""")

    # ---------- 2 where it comes from ----------
    seg28 = segbar([
        dict(name="Enrollment shifts", value=v("enroll_gap"), color="g1",
             tip=f"Enrollment shifts: about {m(v('enroll_gap'), 0)} (stated by CSU)"),
        dict(name="One-time money from FY27 that expires", value=v("fy27_onetime"), color="g2",
             tip=f"One-time FY27 savings that expire: {m(v('fy27_onetime'))} (our inference that this is inside the total)"),
        dict(name="Everything else", value=resid_lo, color="g3",
             tip=f"Everything else: {m(resid_lo)} at the low end (what is left over; not a published line)"),
    ], gap_lo)
    fy28_fig = figure(
        f"What is inside the FY28 gap (low end of the range, {m(gap_lo)})",
        legend([("g1", "Enrollment shifts (CSU's figure)"),
                ("g2", "FY27 one-time money that expires (our inference)"),
                ("g3", "Everything else: cost growth beyond new revenue (remainder)")]) + seg28,
        f"CSU has published two numbers: the total and the roughly {m(v('enroll_gap'), 0)} from enrollment. Its "
        f"budget notes say FY27's one-time funds expire in FY28, so we infer that {m(v('fy27_onetime'))} is inside "
        f"the total. The last block is simply what is left; the high end of the range adds {m(gap_hi - gap_lo)} "
        f"to it. The slides that held CSU's own breakdown are blank in the posted file.",
        ["csu", "infer", "calc"],
        src("memo_oct7", "forum_oct14", "forum_may13"),
        details_table(["Piece", "Amount", "Basis"],
                      [["Enrollment shifts", f"about {m(v('enroll_gap'), 0)}", "Stated by CSU"],
                       ["FY27 one-time money that expires", m(v("fy27_onetime"), 3), "Our inference that it is inside the total"],
                       ["Everything else", f"{m(resid_lo)}–{m(rest_hi - v('fy27_onetime'))}", "Remainder, not a published line"],
                       ["Total", f"{m(gap_lo)}–{m(gap_hi)}", "Stated by CSU"]]))

    fy27_money = hbars([
        dict(label="New money coming in", sub="after financial aid", value=v("fy27_net_new_resources"),
             color="c-rev", tip=f"FY27 net new resources: {m(v('fy27_net_new_resources'), 3)}"),
        dict(label="New costs", sub="before any cuts", value=v("fy27_new_expenses"),
             color="c-cost", tip=f"FY27 new expenses: {m(v('fy27_new_expenses'), 3)}"),
    ], 75, cls="big")
    fy27_tbl = table(
        ["FY27 budget line", "Amount"],
        [["Tuition rate increases (3.5% resident, 4% nonresident, 3% graduate, plus vet med and differential)", "+" + m(v("v4_rates"))],
         ["Fewer students", "&minus;" + m(-v("v4_enroll"))],
         ["State funding", "&minus;" + m(-v("v4_state"))],
         ["Other new resources", "+" + m(v("v4_other_rev"))],
         ["More financial aid", "&minus;" + m(-v("v4_aid"))],
         ["<strong>New money available</strong>", "<strong>" + m(v("fy27_net_new_resources")) + "</strong>"],
         ["Pay and benefits (3% pool, classified raises, promotions, fringe)", m(v("v4_comp"))],
         ["Mandatory costs (bond payments, new buildings, insurance, utilities, library)", m(v("v4_mandatory"))],
         ["Multi-year strategic investments", m(v("v4_strategic"))],
         ["Academic incentive funding (differential tuition, tuition sharing)", m(v("v4_incentive"))],
         ["Other", m(v("v4_other_exp"))],
         ["<strong>New costs</strong>", "<strong>" + m(v("fy27_new_expenses")) + "</strong>"],
         ["<strong>Gap that had to be closed</strong>", "<strong>" + m(v("fy27_gap")) + "</strong>"]],
        "CSU's FY27 budget, as presented May 13, 2026")
    fy27_fig = figure(
        "This year's budget shows the mechanism: new money versus new costs",
        fy27_money + fy27_tbl,
        f"Tuition rates went up and raised {m(v('v4_rates'))}. Falling enrollment, flat state funding and added "
        f"financial aid took most of that back. Pay and benefits alone ({m(v('v4_comp'))}) cost about five times "
        f"the new money that was left.",
        ["csu", "calc"],
        src("forum_may13"))

    lc_rows = [[f"FY{str(fy)[2:]}", m(S[fy]["nr"]), m(S[fy]["res"]), m(S[fy]["state"]),
                n(S[fy]["nr_fte"]), n(S[fy]["res_fte"])] for fy in sorted(S)]
    line_fig = figure(
        "For a decade, out-of-state tuition paid for CSU's growth. In FY26 it turned down.",
        legend([("s1", "Nonresident tuition"), ("s2", "Resident tuition (paid by students)"),
                ("s3", "State support (fee-for-service + College Opportunity Fund)")])
        + '<div class="lc">' + linechart(760, 380) + linechart(390, 330, compact=True) + "</div>",
        f"General campus budget, actual dollars, not adjusted for inflation. From FY15 to FY25 nonresident tuition "
        f"grew {m(nr_growth_peak)} ({pct(p['nr'] / a['nr'] - 1)}), resident tuition {m(res_growth_peak)} "
        f"({pct(p['res'] / a['res'] - 1)}) and state support {m(state_growth_peak)} "
        f"({pct(p['state'] / a['state'] - 1)}). Prices rose {pct(cpi_15_25)} over the same years.",
        ["csu", "calc"],
        src("bdb") + "; inflation from " + src("bls"),
        details_table(["Year", "Nonresident tuition", "Resident tuition", "State support",
                       "Nonresident student FTE", "Resident student FTE"], lc_rows,
                      "CSU general campus, actuals reported to the state"))

    hc_rows = [dict(label=f"Fall {fy}", value=HEADCOUNT[fy][1], color="c-s1",
                    value_label=n(HEADCOUNT[fy][1]),
                    tip=f"Fall {fy}: {n(HEADCOUNT[fy][1])} nonresident students; {n(HEADCOUNT[fy][0])} resident")
               for fy in sorted(HEADCOUNT)]
    hc_fig = figure(
        f"Nonresident students on campus: down {pct(-nr_head_drop, 1)} in two years",
        hbars(hc_rows, 10500, cls="compact", unit_fmt=lambda x: n(x)),
        f"Resident Instruction students at fall census. Over the same two years resident enrollment rose from "
        f"{n(HEADCOUNT[2024][0])} to {n(HEADCOUNT[2026][0])}, but a resident student brings CSU much less revenue.",
        ["csu", "calc"],
        src("factbook27") + ", Table 3",
        details_table(["Fall", "Nonresident", "Resident"],
                      [[str(fy), n(HEADCOUNT[fy][1]), n(HEADCOUNT[fy][0])] for fy in sorted(HEADCOUNT)]))

    b.append(f"""
<section id="causes">
  <div class="wrap">
    <p class="secnum">2</p>
    <h2>Where does it come from?</h2>
    <p class="answer">Costs rise every year. The out-of-state tuition that used to cover the increase has stopped
    growing and started shrinking.</p>

    <h3 class="sub">What CSU has said about next year</h3>
    {fy28_fig}
    <p>The enrollment piece is specific. At the fall 2026 census CSU had {n(v('ri_total'))} on-campus
    students, {n(-v('ri_change'))} fewer than a year earlier. Colorado resident undergraduates were
    <em>up</em> {n(v('res_ug_change'))}. The losses were students who pay the most: domestic nonresident
    undergraduates fell by {n(-v('nr_ug_change'))} (9.7%), international undergraduates by
    {n(-v('intl_ug_change'))} and international graduate students by {n(-v('intl_grad_change'))}. Part of the
    decline is good news with a cost attached: the four-year graduation rate rose from
    {v('gradrate_old')}% to {v('gradrate_new')}%, so fewer students stayed to pay for a fifth year.
    {tag('csu')}</p>

    <h3 class="sub">The mechanism, using this year's published line items</h3>
    <p>CSU has not released line items for FY28, but it did for FY27, and they show how the gap forms.</p>
    {fy27_fig}
    <p>Pay and benefits plus mandatory costs came to {m(core_cost)} in FY27. Tuition rate increases at the
    allowed pace raised {m(v('v4_rates'))}. So even in a year with no enrollment loss at all, a 3% raise would
    cost more than a 3&ndash;4% tuition increase brings in. {tag('calc')} CSU's budget office put it this way
    in January 2026: expenditures are growing faster than revenues, and
    &ldquo;we cannot solely cut our way out of this challenge.&rdquo; {tag('csu')}</p>

    <h3 class="sub">The root: what paid for the last ten years</h3>
    {line_fig}
    <div class="points">
      <div class="point">
        <h3>{pct(nr_share_growth)} of the growth</h3>
        <p>Of all the new tuition and state money CSU's general campus gained between FY15 and FY25,
        {pct(nr_share_growth)} came from nonresident students. Their numbers grew {pct(p['nr_fte'] / a['nr_fte'] - 1)};
        resident student numbers fell {pct(1 - p['res_fte'] / a['res_fte'], 1)}. {tag('calc')}</p>
      </div>
      <div class="point">
        <h3>${nr_per_fte / 1000:.1f}K versus ${(res_per_fte + state_per_res) / 1000:.1f}K</h3>
        <p>In FY26 each nonresident full-time student brought in about ${n(round(nr_per_fte, -2))} of tuition.
        Each resident brought about ${n(round(res_per_fte, -2))} of tuition plus roughly
        ${n(round(state_per_res, -2))} of state support. {tag('calc')}</p>
      </div>
      <div class="point">
        <h3>The state is {pct(state_share)} of this budget</h3>
        <p>Students paid {pct(tuition_share)} of the general campus budget in FY26; nonresidents alone paid
        {pct(nr_share_rev)}. State support was {pct(state_share)}. {tag('calc')}</p>
      </div>
    </div>
    {hc_fig}
    <p>The cost side moved in step with that revenue. CSU's reported cost per student rose from
    ${n(v('cost_per_fte_fy15'))} in FY15 to ${n(v('cost_per_fte_fy26'))} in FY26, an increase of
    {pct(cost_growth)} while consumer prices rose {pct(cpi_15_26)}. Tuition and state revenue per student rose
    {pct(rev_per_growth)}, almost exactly as much, and most of that came from the shift toward nonresident
    students. {tag('csu')} {tag('calc')}</p>

    <div class="rootbox">
      <h3>The root problem, in one paragraph</h3>
      <p>CSU's general-fund costs go up by tens of millions of dollars every year, mostly pay and benefits for
      the people who teach and run the university. For a decade, enrolling more out-of-state students paid for
      that. Out-of-state enrollment peaked in fall 2024 and has fallen {pct(-nr_head_drop, 1)} since. Resident
      tuition and state support are too small and grow too slowly to replace it. Each budget year therefore
      opens with a gap before anyone has made a decision.</p>
    </div>
  </div>
</section>
""")

    # ---------- 3 taxes ----------
    state_rows = [
        dict(label="State funding +1%", sub="all state-funded CSU Fort Collins units",
             value=one_pct_state, color="c-s3",
             tip=f"A 1% increase on {m(v('state_total_fy27'))} of state support = {m(one_pct_state)}"),
        dict(label="State funding +3%", sub="the most optimistic scenario CSU modeled",
             value=three_pct_state, color="c-s3",
             tip=f"A 3% increase = {m(three_pct_state)}"),
        dict(label="FY28 gap", sub="low end of the range", value=gap_lo, value2=gap_hi, color="c-gap",
             value_label=f"{m(gap_lo)}–{m(gap_hi)}",
             tip=f"FY28 projected gap: {m(gap_lo)} to {m(gap_hi)}"),
    ]
    b.append(f"""
<section id="taxes">
  <div class="wrap">
    <p class="secnum">3</p>
    <h2>Colorado just passed new taxes. Doesn't that fix it?</h2>
    <p class="answer">No. None of the new money is for university operating budgets, and one measure takes money
    out of the pool higher education is funded from.</p>

    <p>On November 3, 2026, voters approved three measures that change how much money the state keeps and where
    it goes. Results are unofficial until certified. Amendment 87 passed with about {v('a87_yes')}% of the vote
    and was challenged in court on November 19. {tag('news')}</p>

    <div class="cards">
      <article class="card">
        <h3>Amendment 87 <span class="cardsub">graduated income tax</span></h3>
        <p class="cardnum">{m(v('a87_fy28') / 1000, 2).replace('M', ' billion')}</p>
        <p class="cardcap">estimated new revenue in FY 2027&ndash;28 {tag('state')}</p>
        <p><strong>Where it must go:</strong> K-12 education, health care, and early childhood care and
        education. Higher education is not on the list.</p>
        <p><strong>The catch:</strong> the state's ballot booklet says of the new money,
        &ldquo;It must add to, and not replace, spending on those services.&rdquo; So it cannot simply be swapped
        in to free up existing state dollars for other uses.</p>
      </article>
      <article class="card">
        <h3>Proposition NN <span class="cardsub">keep revenue above the TABOR cap</span></h3>
        <p class="cardnum">{m(v('nn_fy28'), 0)}</p>
        <p class="cardcap">estimated revenue kept in FY 2027&ndash;28 instead of refunded {tag('state')}</p>
        <p><strong>Where it must go:</strong> for the first ten years, K-12 education and programs for children,
        after reimbursing local governments for property tax exemptions.</p>
        <p><strong>The catch:</strong> in FY27 and again in FY28 it moves {m(v('nn_gf_shift'))} that would have
        been available for the general state budget into the new children's account. That general budget is
        where university funding comes from.</p>
      </article>
      <article class="card">
        <h3>Proposition 137 <span class="cardsub">sporting goods sales tax to conservation</span></h3>
        <p class="cardnum">{m(v('p137_fy28'), 0)}</p>
        <p class="cardcap">estimated transfer in FY 2027&ndash;28 {tag('state')}</p>
        <p><strong>Where it must go:</strong> parks and open space, wildfire and forest work, watersheds, outdoor
        recreation. Up to {m(v('p137_csfs'))} goes to the Colorado State Forest Service, which CSU operates.</p>
        <p><strong>The catch:</strong> Forest Service money is for forest and wildfire programs. It is budgeted
        separately from teaching and cannot close a gap in the general fund.</p>
      </article>
    </div>
    <p class="fine">Source for all three: {src("bluebook")}, pp. 33&ndash;47 and 64&ndash;68. The booklet also
    notes that Proposition 137 may reduce the amount actually kept under Proposition NN.</p>

    <h3 class="sub">Meanwhile, the state's own budget is still short</h3>
    <p>The governor's November 2 proposal was released against a projected state shortfall of about
    ${v('state_gap')} billion for FY 2027&ndash;28, driven largely by Medicaid. It would let universities raise
    tuition 3% for residents and 4% for nonresidents. A new governor and a new Joint Budget Committee take over in
    January, and the final budget is usually not settled until April or May. The governor has also told
    legislators that without changes to Medicaid, that program would absorb the Amendment 87 money within about
    three years. {tag('news')}</p>

    {figure("What a state funding increase is worth to CSU, next to the gap",
            hbars(state_rows, 75, cls="big"),
            f"The state sent CSU Fort Collins {m(v('state_total_fy27'))} in FY27, across the general campus, the "
            f"veterinary program, Extension, the Agricultural Experiment Station and the Forest Service. Each 1% is "
            f"worth {m(one_pct_state)} at most; the general campus share is about half of that "
            f"({m(one_pct_general)} per 1%). Closing the gap with state money alone would take an increase of "
            f"{pct(state_needed_lo)}&ndash;{pct(state_needed_hi)}.",
            ["csu", "calc"],
            src("obs_fy27", "bdb", "memo_oct7"),
            details_table(["Item", "Amount"],
                          [["State funding to CSU Fort Collins, FY27", m(v("state_total_fy27"), 3)],
                           ["A 1% increase", m(one_pct_state, 2)],
                           ["A 3% increase", m(three_pct_state, 2)],
                           ["FY28 gap", f"{m(gap_lo)}–{m(gap_hi)}"]]))}

    <div class="callout">
      <h3>Could the new money help indirectly?</h3>
      <p>At the margins, possibly. The legislature decides the details, and if Amendment 87 survives in court
      and takes pressure off schools and Medicaid, lawmakers may have more room elsewhere. That is a hope, not a
      line in any budget. What the documents establish is narrower: no measure dedicates money to university
      operations, the largest one must add to spending rather than replace it, and CSU's best-case scenario for
      state funding is worth about {m(three_pct_state, 0)} against a gap of {m(gap_lo, 0)} or more.
      {tag('calc')} {tag('infer')}</p>
    </div>
  </div>
</section>
""")

    # ---------- 4 things people point to ----------
    fp_rows = [
        dict(label="FY28 gap", sub="projected, recurring", value=gap_lo, value2=gap_hi, color="c-gap",
             value_label=f"{m(gap_lo)}–{m(gap_hi)}", tip=f"FY28 projected gap: {m(gap_lo)} to {m(gap_hi)}"),
        dict(label="All central administration", sub="general campus, FY26 actual spending",
             value=v("inst_support"), color="c-gray",
             tip=f"'Institutional Support' (executive, finance, HR, legal, general administration): {m(v('inst_support'))}, {n(v('inst_support_fte'))} FTE"),
        dict(label="Debt payments from the general fund", sub="FY26 budget", value=v("debt_service"),
             color="c-gray", tip=f"Debt service in the general-fund budget, FY26: {m(v('debt_service'))}"),
        dict(label="Athletics' general-fund allocation", sub="FY26 budget", value=v("athletics_eg"),
             color="c-gray", tip=f"Athletics general-fund allocation, FY26: {m(v('athletics_eg'))}"),
        dict(label="Three separation payouts", sub="reported; one-time, not yearly", value=payouts,
             color="c-gray", value_label=m(payouts),
             tip=f"Reported payouts: Parsons {m(v('payout_parsons'))}, Norvell {m(v('payout_norvell'))}, Underwood ${v('payout_underwood') * 1000:.0f}K"),
    ]
    b.append(f"""
<section id="flashpoints">
  <div class="wrap">
    <p class="secnum">4</p>
    <h2>What about administration, athletics, debt and payouts?</h2>
    <p class="answer">They are real costs and fair questions. None is large enough, or growing fast enough, to be
    the cause.</p>

    {figure("Common explanations, drawn to the same scale as the gap",
            hbars(fp_rows, 75, cls="big"),
            "Each gray bar is the entire amount, not a plausible saving. The gap recurs every year; the payouts "
            "happened once.",
            ["csu", "state", "news"],
            src("bdb", "colobs_fy26", "collegian_react"),
            details_table(["Item", "Amount", "Basis"],
                          [["FY28 gap", f"{m(gap_lo)}–{m(gap_hi)}", "CSU projection"],
                           ["All central administration (Institutional Support), FY26", m(v("inst_support"), 3), "State filing, actual"],
                           ["Debt service in the general fund, FY26", m(v("debt_service"), 3), "CSU budget"],
                           ["Athletics general-fund allocation, FY26", m(v("athletics_eg"), 3), "CSU budget"],
                           ["Reported separation payouts (Parsons, Norvell, Underwood)", m(payouts, 3), "News reports"]]))}

    <div class="qa">
      <details open>
        <summary>Executive payouts</summary>
        <p>News reports put the payment to departing President Amy Parsons at {m(v('payout_parsons'))}, the
        settlement with former Provost Marion Underwood at ${v('payout_underwood') * 1000:.0f},000 and the
        settlement with former football coach Jay Norvell at {m(v('payout_norvell'))}. Together that is
        {m(payouts)}, paid once. It equals {pct(payouts / gap_lo)} of one year of the gap. The questions these
        raise about transparency are legitimate. They are questions about governance, and answering them would
        not change the budget arithmetic. {tag('news')} {tag('calc')}</p>
      </details>
      <details>
        <summary>Athletics</summary>
        <p>Athletics receives {m(v('athletics_eg'))} from the general fund (FY26), up from
        {m(v('athletics_eg_fy15'))} in FY15. In FY25 the department reported {m(v('ath_rev'))} of revenue, of
        which {m(ath_support)} was direct and indirect university support and {m(v('ath_fees'))} was student
        fees; together those are {pct(ath_support_fees_share)} of its revenue. About {m(v('ath_aid'))} of its
        spending was athletes' scholarships, which return to CSU as tuition, fees, room and board. The
        department carries {m(v('ath_debt'))} of debt, and paid {m(v('ath_debt_service'))} on its bonds in FY25;
        those payments continue whatever sports are played. {tag('csu')} {tag('state')}</p>
        <p>Removing the entire general-fund allocation would cover about
        {pct(v('athletics_eg') / gap_hi)}&ndash;{pct(v('athletics_eg') / gap_lo)} of the gap, once. It would not
        stop the gap from re-forming the following year. {tag('calc')}</p>
      </details>
      <details>
        <summary>Administration and staffing</summary>
        <p>All central administration on the general campus budget (the president's and vice presidents'
        offices, finance, human resources, legal and similar functions) cost {m(v('inst_support'))} in FY26 and
        employed {n(v('inst_support_fte'))} FTE. Eliminating every one of those jobs would not close the gap.
        {tag('csu')}</p>
        <p>Did staffing grow faster than enrollment? Two official counts give different answers, and we could
        not fully reconcile them.</p>
        {table(["Count", "Period", "General-fund employees", "Students (FTE)"],
               [["State filing: all faculty and staff", "FY15–FY26",
                 f"{n(v('cdhe_fte_fy15'))} → {n(v('cdhe_fte_fy26'))} (+{pct(cdhe_fte_growth, 1)})",
                 f"+{pct(stu_growth_15_26, 1)}"],
                ["Fact Book: faculty", "FY15–FY25",
                 f"{n(v('fb_fac_fy15'), 1)} → {n(v('fb_fac_fy25'), 1)} (+{pct(fb_fac_growth, 1)})",
                 f"+{pct(stu_growth_15_25, 1)}"],
                ["Fact Book: administrative professional + state classified", "FY15–FY25",
                 f"{n(v('fb_staff_fy15'), 1)} → {n(v('fb_staff_fy25'), 1)} (+{pct(fb_staff_growth, 1)})",
                 f"+{pct(stu_growth_15_25, 1)}"]])}
        <p>The two sources count part-time and temporary instructors differently. On the Fact Book count,
        staffing did grow faster than enrollment, and that added cost was paid for at the time by rising
        nonresident tuition. It built up over ten years; it did not open a new {m(gap_lo, 0)} hole in one.
        One common confusion is worth clearing up: of CSU's {n(v('ap_total'))} administrative professional FTE,
        only {pct(ap_eg_share)} are paid from the general fund. The rest are paid by research grants, fees and
        self-funded operations. {tag('csu')} {tag('calc')} {tag('infer')}</p>
      </details>
      <details>
        <summary>Debt</summary>
        <p>Debt service charged to the general fund rose from {m(v('debt_service_fy15'))} in FY15 to
        {m(v('debt_service'))} in FY26. That is a real, permanent claim on the budget, and it is why past
        building decisions matter. It is also a legal obligation, so it cannot be cut to close a gap.
        {tag('csu')}</p>
      </details>
    </div>
    <p>Each of these deserves scrutiny on its own terms. The point of the chart is narrower: none of them is
    growing by {m(gap_lo, 0)} a year, so none of them explains why the gap comes back every year.</p>
  </div>
</section>
""")

    # ---------- 5 unknowns ----------
    b.append(f"""
<section id="unknowns">
  <div class="wrap">
    <p class="secnum">5</p>
    <h2>What we do not know</h2>
    <p class="answer">The size of the gap is CSU's first estimate. Several things could move it.</p>
    <ul class="unknowns">
      <li><strong>The line items.</strong> CSU has published the total and the enrollment figure. The two slides
      that showed the detailed scenarios are blank in the posted file, so the split in section 2 rests partly
      on our inference.</li>
      <li><strong>The state budget.</strong> CSU's projection assumed nothing about the ballot measures and
      was made before the governor's proposal. A new governor and budget committee take office in January. The
      Board of Governors is scheduled to see updated versions in December, February and May.</li>
      <li><strong>Amendment 87.</strong> It faces a lawsuit, and the legislature has not yet decided how to
      spend its revenue.</li>
      <li><strong>Raises.</strong> The range reflects 0%, 1% and 3% compensation scenarios. A working group on
      compensation is due to report in mid-December.</li>
      <li><strong>Next fall's class.</strong> Enrollment drives the largest known piece of the gap, and fall
      2027 enrollment is not knowable yet.</li>
      <li><strong>Staffing counts.</strong> The state filing and the Fact Book disagree about how fast the
      general-fund workforce grew. We show both rather than pick one.</li>
      <li><strong>CSU's own slides disagree in places.</strong> For example, two slides in the October 14 deck
      give different figures for the drop in international students. We used the summary slide.</li>
    </ul>
  </div>
</section>
""")

    # ---------- 6 agree ----------
    b.append(f"""
<section id="agree">
  <div class="wrap">
    <p class="secnum">6</p>
    <h2>What the evidence supports</h2>
    <p class="answer">Five statements to agree or disagree with before anyone argues about solutions.</p>
    <ol class="agree">
      <li><strong>The gap is structural.</strong> It appears in every scenario CSU modeled, it follows a
      {m(v('fy27_gap'), 0)} gap this year, and part of it is one-time money from this year coming due.</li>
      <li><strong>The largest identified driver is enrollment mix.</strong> CSU attributes about
      {m(v('enroll_gap'), 0)} to enrollment, and the losses are concentrated among nonresident and international
      students, who had supplied most of the past decade's revenue growth.</li>
      <li><strong>Normal cost growth outruns normal revenue growth.</strong> In FY27, pay, benefits and
      mandatory costs rose {m(core_cost)} while tuition rate increases raised {m(v('v4_rates'))}.</li>
      <li><strong>The state is not positioned to close it.</strong> State support is {pct(state_share)} of the
      general campus budget, the state has its own shortfall, and the new taxes are dedicated to other
      purposes.</li>
      <li><strong>The most visible grievances are not the cause.</strong> Payouts, athletics, administration and
      debt are all smaller than the gap and none is growing at its pace.</li>
    </ol>
    <p>This page takes no position on what CSU should do. If any of the five statements is wrong, the place to
    show it is in the <a href="sources.html#ledger">figure ledger</a>, where every number is tied to a document
    and page.</p>
    <p>A separate page, <a href="csu-2030.html">CSU in 2030: two scenarios</a>, sketches where two different
    responses could lead. It is a thought experiment built on stated assumptions and is marked as such; it is
    not part of the evidence on this page.</p>
  </div>
</section>
""")

    body = "\n".join(b)
    return page("CSU's FY28 budget gap: scale and causes",
                "An independent, source-linked look at Colorado State University's projected FY 2027-28 "
                "budget gap: how big it is, where it comes from, and why new state taxes do not close it.",
                body, "index")


# ----------------------------------------------------------------------------
# SOURCES PAGE
# ----------------------------------------------------------------------------
CORRECTIONS = [
    ("The claim that no number came from AI memory was not true.",
     "The first version said every figure was computed from archived filings. Several statements had no archived "
     "source at all, including contract details for the football coach, terms of the president's departure, and "
     "the election results. Those that could be confirmed are now cited to news reports and labeled as such. "
     "Those that could not were removed."),
    ("A paragraph about a named private individual was removed.",
     "The first version included a 'record check' asserting that a named Title IX consultant had no connection "
     "to CSU. Nothing in the archive supported the paragraph in either direction, and it is not the kind of "
     "claim to publish about a person without evidence."),
    ("The FY28 gap was presented as a three-part breakdown that CSU never published.",
     "CSU has published the total ($61.3M-$70.7M) and the enrollment figure (about $25M). The first version showed a "
     "third bar, 'mandatory costs, compensation and state squeeze' of $21.2M-$30.6M, as if it were a finding. It was "
     "the remainder after subtracting the other two. Whether the $15.1M of expiring one-time money sits inside "
     "CSU's total is an inference. The slides that held CSU's breakdown (slides 14-15 of the Oct. 14 deck) are "
     "blank in the posted PDF. This version labels each piece accordingly."),
    ("Amendment 87 was described as relieving pressure on higher education funding.",
     "The first version said the amendment would absorb K-12 and Medicaid costs and estimated $6.3M-$10.6M more "
     "per year for CSU. The state's ballot booklet says the new revenue must add to, and not replace, spending "
     "on K-12, health care and early childhood. The estimate was speculation and has been removed."),
    ("A pie chart assigned percentage 'weights' to causes with no calculation behind them.",
     "The '45% payroll, 22% debt, 17% athletics, 16% state' chart was labeled illustrative, but the numbers were "
     "invented. It has been removed."),
    ("Athletics support was understated, then used to size the remaining gap.",
     "The first version netted athletes' scholarships out of university support to reach '$15.6M net' and "
     "concluded that 76% of the gap would remain without athletics. Whether to net out scholarships is a "
     "judgment, not a fact. This version reports the figures as filed: $26.0M of direct and indirect support, "
     "$6.1M of student fees, and a $17.2M general-fund allocation. The state auditor's report is also an "
     "agreed-upon-procedures engagement on an unaudited statement, not an audit, and is now described that way."),
    ("The staffing headline used the one data source that showed the least growth.",
     "'Workforce grew 7.0%, matching enrollment at 6.6%' came from the state filing. CSU's Fact Book shows "
     "general-fund faculty up 13.0% and other staff up 19.6% over nearly the same period. The first version also "
     "compared staff growth measured from FY15 with faculty growth measured from FY17. Both counts are now shown "
     "side by side with the same base year, and the disagreement is stated."),
    ("The '$885M E&G budget' includes units with their own appropriations.",
     "That total includes the veterinary program, the Agricultural Experiment Station, Extension and the Forest "
     "Service. The general campus budget is about $700M. As a result the first version overstated the state's "
     "share of the budget where the gap sits (23% rather than 16%) and the value of a 1% state increase to "
     "that budget ($2.1M rather than about $1.1M)."),
    ("The October 7 budget message was attributed to the president.",
     "It was signed by the Vice President for University Operations and Chief Financial Officer."),
    ("Comparisons that rested on weak or unverified sources were removed.",
     "Athletics debt medians attributed to a federal GAO report came from a third-party blog summary. NCAA "
     "tournament payout scenarios used unsourced assumptions. Peer comparisons from federal IPEDS data were not "
     "re-verified in this audit. None of these is needed for the argument, so they are gone."),
    ("Two international-enrollment figures from different slides were mixed.",
     "CSU's October 14 deck gives different numbers on slides 5 and 6. This version uses slide 5 and says so."),
    ("Data-parsing errors in the first version's intermediate files.",
     "For example, the FY15 College Opportunity Fund stipend was read as $15 and FY15 average faculty "
     "compensation as $206,154. These did not reach the headline numbers, but the series used here were "
     "re-extracted and checked row by row."),
]


def build_sources():
    led_rows = []
    for k, (val, unit, desc, sid, loc, kind) in F.items():
        s = SOURCES[sid]
        if unit == "$M":
            vs = m(val, 3 if abs(val) < 1000 and round(val, 1) != val else 1)
        elif unit == "$B":
            vs = f"${val}B"
        elif unit == "$":
            vs = f"${val:,.0f}"
        elif unit == "%":
            vs = f"{val}%"
        else:
            vs = f"{val:,} {unit}"
        led_rows.append([e(desc), vs, tag(kind), f'<a href="{e(s["url"])}">{e(s["title"])}</a>', e(loc)])
    ledger_tbl = table(["Figure", "Value", "Kind", "Document", "Where in it"], led_rows)

    src_rows = [[f'<a href="{e(s["url"])}">{e(s["title"])}</a>', e(s["publisher"])] for s in SOURCES.values()]
    src_tbl = table(["Document", "Publisher"], src_rows)

    corr = "".join(f"<li><strong>{e(h)}</strong> {e(t)}</li>" for h, t in CORRECTIONS)

    body = f"""
<section class="hero small">
  <div class="wrap">
    <p class="eyebrow">Sources, methods and corrections</p>
    <h1>How this was made, and how to check it</h1>
    <p class="lede">Everything on the main page traces to a public document. This page says who made the
    analysis and how, lists every figure with its source, and records what was wrong in the first version.</p>
  </div>
</section>

<section id="disclosure">
  <div class="wrap">
    <h2>Disclosure</h2>
    <ul class="unknowns">
      <li><strong>Author.</strong> Matthew R. V. Ross, acting as an individual. This is not a publication of
      Colorado State University or the CSU System, and no one at the university reviewed it.</li>
      <li><strong>Use of AI.</strong> AI coding agents did most of the work. The first version (November 19&ndash;20,
      2026) was built with Google's Gemini in the Antigravity agent: it downloaded the source documents, wrote
      the code that reads them, and drafted the pages. On {AS_OF}, Anthropic's Claude re-read the source
      documents, checked each claim against them, searched news coverage for facts not in the archive, removed
      what could not be supported, and rewrote the site. The author directed both passes and is responsible
      for what is published.</li>
      <li><strong>What "checked" means.</strong> For each figure, the AI located the number in the source
      document (or computed it from numbers located there) and recorded the page. Budget slides that exist
      only as images were read from the rendered image. A person has not independently re-keyed every figure.
      AI systems make transcription and reading errors; the ledger below exists so that anyone can check any
      number in a minute.</li>
      <li><strong>Limits.</strong> The analysis uses only public documents. CSU has internal data that could
      change the picture. Election results are unofficial until certified. Facts sourced to news reports rely
      on those outlets' reporting.</li>
      <li><strong>No recommendation.</strong> The site describes the problem. It does not propose or endorse
      any solution.</li>
      <li><strong>Corrections.</strong> Report errors at <a href="{REPO}/issues">{REPO}/issues</a>.</li>
    </ul>
  </div>
</section>

<section id="labels">
  <div class="wrap">
    <h2>What the labels mean</h2>
    {table(["Label", "Meaning"],
           [[tag('csu'), "The number is printed in a CSU budget document, filing or Fact Book."],
            [tag('state'), "The number is printed in a State of Colorado document (ballot booklet, state auditor report)."],
            [tag('news'), "Reported by a news outlet. We do not hold the underlying record."],
            [tag('calc'), "We added, subtracted or divided numbers of the kinds above. The inputs are in the ledger."],
            [tag('infer'), "We concluded this from the documents, but no document states it. Treat it as our reading."]])}
  </div>
</section>

<section id="ledger">
  <div class="wrap">
    <h2>Figure ledger</h2>
    <p>Every number used on the main page. The same list is available as
    <a href="figures.csv">figures.csv</a>. The annual series behind the tuition chart are in the table under
    that chart and in <code>data.py</code> in the <a href="{REPO}">repository</a>.</p>
    {ledger_tbl}
  </div>
</section>

<section id="documents">
  <div class="wrap">
    <h2>Documents</h2>
    {src_tbl}
    <p class="fine">Terms. <em>Fiscal year 2028 (FY28)</em> runs July 1, 2027 to June 30, 2028.
    <em>General fund</em> on this site means CSU's Education and General budget. <em>General campus</em> means
    the main Fort Collins campus as reported to the state, excluding the professional veterinary program and the
    state agencies CSU operates. <em>FTE</em> is full-time equivalent. Dollar figures are not adjusted for
    inflation unless stated.</p>
  </div>
</section>

<section id="corrections">
  <div class="wrap">
    <h2>What the re-audit changed</h2>
    <p>The first version of this site contained errors and unsupported claims. They are listed here so readers
    of that version know what not to rely on.</p>
    <ol class="agree corrections">{corr}</ol>
  </div>
</section>
"""
    return page("Sources, methods and corrections: CSU FY28 budget gap",
                "Who made this analysis, how AI was used, every figure with its source document, and "
                "corrections to the first version.", body, "sources")


# ----------------------------------------------------------------------------
# 2030 SCENARIOS (illustrative; every parameter is in data.SCEN)
# ----------------------------------------------------------------------------
SCEN_YEARS = (2028, 2029, 2030, 2031)
PER_FTE = v("fy27_fte_cut") / v("fy27_permanent")      # positions removed per $1M of permanent cuts in FY27


def run_scenario(sc):
    c = SCEN["common"]
    t_nr, t_res = v("t_nr_fy27"), v("t_res_fy27")
    st, comp = v("state_total_fy27"), v("comp_base_fy27")
    res_head, nr_head = HEADCOUNT[2026]
    cum, carry, pay = v("fy27_permanent"), 0.0, 1.0
    years = []
    for i, fy in enumerate(SCEN_YEARS):
        e_nr, e_res = sc["e_nr"][i], sc["e_res"][i]
        if i == 0:
            gap = c["gap_fy28"]          # CSU's own projection; tuition total assumed level with FY27
            st *= 1 + c["state"]
        else:
            d_nr = t_nr * ((1 + e_nr) * (1 + c["rate_nr"]) - 1)
            d_res = t_res * ((1 + e_res) * (1 + c["rate_res"]) - 1)
            d_st = st * c["state"]
            cost = (sc["raises"][i] * comp + sc["benefits"][i] + c["mandatory"] + c["aid"] + sc["invest"][i])
            gap = carry + cost - (d_nr + d_res + d_st + sc["newrev"][i])
            t_nr, t_res, st = t_nr + d_nr, t_res + d_res, st + d_st
        nr_head *= 1 + e_nr
        res_head *= 1 + e_res
        perm = (1 - sc["onetime"][i]) * gap
        one = sc["onetime"][i] * gap
        carry = one
        cum += perm
        pay *= (1 + sc["raises"][i]) / (1 + c["inflation"])
        comp = comp * (1 + sc["raises"][i]) + sc["benefits"][i] - v("personnel_share") / 100 * perm
        years.append(dict(fy=fy, gap=gap, perm=perm, one=one, cum=cum, nr_head=nr_head,
                          res_head=res_head, tuition=t_nr + t_res, raise_=sc["raises"][i]))
    return dict(years=years, cum=cum, positions=cum * PER_FTE, nr_head=nr_head, res_head=res_head,
                real_pay=pay - 1, tuition=t_nr + t_res, carry=carry)


_fail = dict(SCEN["decide"])
_fail.update(e_nr=SCEN["drift"]["e_nr"], e_res=SCEN["drift"]["e_res"], newrev=[0, 0, 0, 0])
RESULTS = {"drift": run_scenario(SCEN["drift"]), "decide": run_scenario(SCEN["decide"]),
           "decide_fail": run_scenario(_fail)}


def r5(x):
    return int(round(x / 5.0) * 5)


def r10(x):
    return int(round(x / 10.0) * 10)


def r100(x):
    return int(round(x / 100.0) * 100)


def gapchart(W, H, compact=False):
    A, B = RESULTS["drift"]["years"], RESULTS["decide"]["years"]
    ml, mr, mt, mb = (44, 150, 16, 34) if not compact else (52, 16, 16, 34)
    pw, ph = W - ml - mr, H - mt - mb
    xs = [2027] + list(SCEN_YEARS)
    ymax = 80.0

    def X(fy):
        return ml + (fy - xs[0]) / (xs[-1] - xs[0]) * pw

    def Y(val):
        return mt + ph - val / ymax * ph

    fs = 13 if not compact else 12
    o = [f'<svg viewBox="0 0 {W} {H}" class="linechart {"compact" if compact else "wide"}" role="img" '
         f'aria-label="Line chart of the yearly budget gap under two scenarios, fiscal years 2027 to 2031. '
         f'Values are in the table below.">']
    for g in (0, 20, 40, 60, 80):
        o.append(f'<line class="grid" x1="{ml}" x2="{ml + pw}" y1="{Y(g):.1f}" y2="{Y(g):.1f}"/>')
        o.append(f'<text class="axis" x="{ml - 6}" y="{Y(g) + 4:.1f}" text-anchor="end" font-size="{fs}">'
                 f'{"$0" if g == 0 else f"${g}M"}</text>')
    for fy in xs:
        o.append(f'<text class="axis" x="{X(fy):.1f}" y="{H - 12}" text-anchor="middle" font-size="{fs}">'
                 f'FY{str(fy)[2:]}</text>')
    g27, g28 = v("fy27_gap"), SCEN["common"]["gap_fy28"]
    o.append(f'<polyline class="line hist" points="{X(2027):.1f},{Y(g27):.1f} {X(2028):.1f},{Y(g28):.1f}"/>')
    for rows, cls in ((A, "a1"), (B, "b1")):
        pts = " ".join(f'{X(r["fy"]):.1f},{Y(max(r["gap"], 0)):.1f}' for r in rows)
        o.append(f'<polyline class="line {cls}" points="{pts}"/>')
    o.append(f'<circle class="dot hist" cx="{X(2027):.1f}" cy="{Y(g27):.1f}" r="5"/>')
    o.append(f'<circle class="dot hist" cx="{X(2028):.1f}" cy="{Y(g28):.1f}" r="5"/>')
    o.append(f'<text class="note" x="{X(2027) + 8:.1f}" y="{Y(g27) + 20:.1f}" font-size="{fs}">'
             f'{m(g27)} closed</text>')
    o.append(f'<text class="note" x="{X(2028):.1f}" y="{Y(g28) - 12:.1f}" text-anchor="middle" '
             f'font-size="{fs}">{m(g28, 0)} projected</text>')
    for rows, cls, name in ((A, "a1", SCEN["drift"]["name"]), (B, "b1", SCEN["decide"]["name"])):
        last = rows[-1]
        o.append(f'<circle class="dot {cls}" cx="{X(last["fy"]):.1f}" cy="{Y(last["gap"]):.1f}" r="5"/>')
        if not compact:
            o.append(f'<text class="endlabel" x="{X(last["fy"]) + 10:.1f}" y="{Y(last["gap"]) - 2:.1f}" '
                     f'font-size="13">{e(name)}</text>')
            o.append(f'<text class="endval" x="{X(last["fy"]) + 10:.1f}" y="{Y(last["gap"]) + 14:.1f}" '
                     f'font-size="13">about {m(last["gap"], 0)} a year</text>')
    half = pw / (len(xs) - 1) / 2
    for i, fy in enumerate(xs):
        if fy == 2027:
            tip = f'FY27 — gap of {m(g27)} closed (actual)'
        else:
            a_, b_ = A[i - 1], B[i - 1]
            tip = (f'FY{str(fy)[2:]} — {SCEN["drift"]["name"]}: {m(a_["gap"], 0)} · '
                   f'{SCEN["decide"]["name"]}: {m(b_["gap"], 0)}')
        o.append(f'<rect class="hit" x="{X(fy) - half:.1f}" y="{mt}" width="{2 * half:.1f}" height="{ph}" '
                 f'tabindex="0" data-tip="{e(tip)}"/>')
    o.append("</svg>")
    return "\n".join(o)


def build_2030():
    c = SCEN["common"]
    D, E, Fl = RESULTS["drift"], RESULTS["decide"], RESULTS["decide_fail"]
    na, nb = SCEN["drift"]["name"], SCEN["decide"]["name"]
    base = v("reducible")
    first_year_pos_b = E["years"][0]["perm"] * PER_FTE
    first_year_pos_a = D["years"][0]["perm"] * PER_FTE
    nr24 = HEADCOUNT[2024][1]

    def pct_list(xs):
        return ", ".join(f"{x * 100:+.1f}%".replace(".0%", "%") for x in xs)

    def money_list(xs):
        return ", ".join(f"${x}M" for x in xs)

    gap_tbl = [[f"FY{str(a_['fy'])[2:]}", m(a_["gap"], 0), m(a_["perm"], 0), m(a_["one"], 0),
                m(b_["gap"], 0), m(b_["perm"], 0)]
               for a_, b_ in zip(D["years"], E["years"])]
    gap_fig = figure(
        "The gap that has to be closed each year",
        legend([("a1", na), ("b1", nb), ("grayc", "Actual and CSU's projection")])
        + '<div class="lc">' + gapchart(760, 360) + gapchart(390, 320, compact=True) + "</div>",
        f"Both paths start from the same {m(c['gap_fy28'], 0)} gap in FY28, the midpoint of CSU's range. "
        f"Under &ldquo;{na}&rdquo; the gap keeps coming back at {m(D['years'][-1]['gap'], 0)}&ndash;"
        f"{m(D['years'][1]['gap'], 0)} a year, partly because each year's one-time money returns the next "
        f"year. Under &ldquo;{nb}&rdquo; it shrinks, if the enrollment assumptions hold.",
        ["csu", "scen"],
        "FY27 and FY28 from " + src("forum_may13", "memo_oct7") + "; FY29&ndash;FY31 are scenario arithmetic",
        details_table(["Year", f"{na}: gap", "closed permanently", "covered one-time",
                       f"{nb}: gap", "closed permanently"], gap_tbl))

    cum_fig = figure(
        "Permanent reductions since FY27, added up through FY31",
        hbars([
            dict(label=na, sub="spread across units, a little each year", value=D["cum"], color="c-a",
                 value_label=f"about {m(r5(D['cum']), 0)}",
                 tip=f"{na}: {m(D['cum'], 0)} of cumulative permanent reductions, FY27-FY31"),
            dict(label=nb, sub="concentrated in FY28 and FY29", value=E["cum"], color="c-b",
                 value_label=f"about {m(r5(E['cum']), 0)}",
                 tip=f"{nb}: {m(E['cum'], 0)} of cumulative permanent reductions, FY27-FY31"),
        ], 230, cls="big"),
        f"Neither path avoids large cuts. By FY31 the totals are {pct(D['cum'] / base)} and "
        f"{pct(E['cum'] / base)} of the {m(base, 0)} CSU called reducible in 2026. Under &ldquo;{na}&rdquo; "
        f"another {m(D['carry'], 0)} is still being covered with one-time money in FY31 and comes due in FY32.",
        ["scen", "csu"],
        "scenario arithmetic; " + src("forum_may13", "forum_apr13"),
        details_table(["Scenario", "Cumulative permanent reductions FY27–FY31", "Share of $551M", "Positions (approx.)"],
                      [[na, m(D["cum"], 0), pct(D["cum"] / base), n(r10(D["positions"]))],
                       [nb, m(E["cum"], 0), pct(E["cum"] / base), n(r10(E["positions"]))]]))

    def scen_card(key, R, cls, tagline, bullets):
        sc = SCEN[key]
        return f"""<article class="scen {cls}">
      <h3>{e(sc['name'])}</h3>
      <p class="scen-tag">{tagline}</p>
      <ul>{''.join(f'<li>{x}</li>' for x in bullets)}</ul>
      <dl>
        <dt>Gap still opening in FY31</dt><dd>about {m(R['years'][-1]['gap'], 0)} a year</dd>
        <dt>Permanent cuts, FY27&ndash;FY31</dt><dd>about {m(r5(R['cum']), 0)}</dd>
        <dt>Positions eliminated since 2026</dt><dd>roughly {n(r10(R['positions']))}</dd>
        <dt>Nonresident students, fall 2030</dt><dd>about {n(r100(R['nr_head']))}</dd>
        <dt>Pay after inflation, FY27 to FY31</dt><dd>{R['real_pay'] * 100:+.0f}%</dd>
      </dl>
      <p class="fine">{tag('scen')} Computed from the assumptions listed at the bottom of this page.</p>
    </article>"""

    cards = scen_card("drift", D, "", "Close each year's gap as it arrives", [
        "Every fall a new gap is announced. Each college and division gets a percentage target.",
        "Units cut what can be cut fastest: vacant lines, instructors on short contracts, advisors, staff, operating budgets.",
        "About a quarter of each gap is covered with one-time money, as in FY27. It comes back the next year.",
        "Raises are held near 1% to limit the cuts.",
        "No program is closed on purpose. Many shrink below the size at which they work.",
    ]) + scen_card("decide", E, "b", "Choose the smaller university on purpose", [
        "In 2027, leadership and shared governance decide what size CSU will be and which programs it will grow, merge or end.",
        f"The whole FY28 gap is closed with permanent decisions. No one-time money is used to defer it.",
        f"A one-time transition fund ({m(SCEN['decide']['restructure'], 0)} assumed, from reserves) pays for severance, teach-outs and consolidation.",
        "Part of the savings is reinvested in recruiting, retention and a few new programs.",
        "Raises return to 3% by FY30, for a smaller workforce.",
    ])

    assume_rows = [
        ["FY28 gap", m(c["gap_fy28"], 0), m(c["gap_fy28"], 0), "Midpoint of CSU's range"],
        ["Tuition rate increase, resident / nonresident", "3% / 4% a year", "3% / 4% a year", "Caps in the governor's Nov. 2 proposal"],
        ["State funding", "+1% a year", "+1% a year", "Middle of CSU's 0%, 1%, 3% scenarios"],
        ["Inflation", "3% a year", "3% a year", "Average of the past eleven years"],
        ["Mandatory cost growth", m(c["mandatory"]) + " a year", m(c["mandatory"]) + " a year", "Held at the FY27 amount"],
        ["Financial aid growth", m(c["aid"]) + " a year", m(c["aid"]) + " a year", "Held at the FY27 amount"],
        ["Raises, FY28–FY31", pct_list(SCEN["drift"]["raises"]), pct_list(SCEN["decide"]["raises"]), "Author's assumption"],
        ["Benefit cost growth", "$10M a year", "$8M a year", "Author's assumption; CSU cited a $15M fringe increase for FY27"],
        ["Nonresident enrollment, falls 2027–2030", pct_list(SCEN["drift"]["e_nr"]), pct_list(SCEN["decide"]["e_nr"]),
         "Author's assumption; the last two falls were -6.7% and -9.7%"],
        ["Resident enrollment, falls 2027–2030", pct_list(SCEN["drift"]["e_res"]), pct_list(SCEN["decide"]["e_res"]),
         "Author's assumption; Colorado graduates are projected to fall 14% by 2041"],
        ["Share of each gap covered with one-time money", "25%", "0%", "FY27 was 28%"],
        ["New revenue from new or expanded programs (added each year FY29–FY31)", "none", money_list(SCEN["decide"]["newrev"][1:]), "Author's assumption"],
        ["New spending on recruiting and retention (added each year FY29–FY31)", "none", money_list(SCEN["decide"]["invest"][1:]), "Author's assumption"],
        ["One-time transition cost, from reserves", "none", m(SCEN["decide"]["restructure"], 0), "Author's assumption"],
        ["Positions removed per $1M of permanent cuts", f"{PER_FTE:.1f}", f"{PER_FTE:.1f}", "FY27 actual: 160.58 positions for $39.2M"],
        ["Share of cuts that reduce the payroll base", "60%", "60%", "CSU's FY27 guideline for cut proposals"],
    ]

    body = f"""
<section class="hero">
  <div class="wrap">
    <p class="eyebrow">A thought experiment &middot; not a forecast</p>
    <h1>CSU in 2030: two ways this could go</h1>
    <p class="lede">The <a href="index.html">main page</a> shows that CSU's gap comes back every year. This page asks
    what the university looks like in the 2030&ndash;31 year under two different responses: closing each gap as
    it arrives, or making large decisions early. Both are plausible. Neither is painless.</p>

    <div class="warnbox" role="note">
      <h2>This page is different from the rest of the site</h2>
      <ul>
        <li><strong>It is a scenario exercise, not evidence.</strong> The other pages report what public
        documents say. This one runs simple arithmetic forward on assumptions chosen by the author with an AI
        model. Change the assumptions and the results change.</li>
        <li><strong>It is not a CSU plan and not a prediction.</strong> No one at CSU has proposed either path
        in this form. The scenario names and descriptions are the author's.</li>
        <li><strong>It names no programs, units or people.</strong> Which things a university should stop doing
        is a judgment for the people who govern it.</li>
        <li><strong>Every number is labeled.</strong> {tag('scen')} means computed from the assumptions;
        {tag('assume')} means chosen by the author; the other labels mean what they mean elsewhere on the site.
        The full list of assumptions is <a href="#assumptions">at the bottom</a>.</li>
      </ul>
    </div>
  </div>
</section>

<section id="givens">
  <div class="wrap">
    <p class="secnum">1</p>
    <h2>What both scenarios have to live with</h2>
    <p class="answer">The pool of students is shrinking, the costs keep rising, and the state is not coming.</p>
    <div class="points">
      <div class="point">
        <h3>Fewer 18-year-olds</h3>
        <p>The number of U.S. high school graduates is projected to have peaked in 2025 and to fall
        {-v('wiche_us')}% by 2041. Colorado's is projected to fall {-v('wiche_co')}%. Two states that send CSU
        many nonresident students fall much further: California {-v('wiche_ca')}% and Illinois
        {-v('wiche_il')}%. {tag('ext')} {tag('news')}</p>
      </div>
      <div class="point">
        <h3>Nonresidents already leaving</h3>
        <p>Nonresident enrollment fell from {n(nr24)} in fall 2024 to {n(HEADCOUNT[2026][1])} in fall 2026.
        Second-year retention slipped from {v('retention_old')}% to {v('retention_new')}%. {tag('csu')}</p>
      </div>
      <div class="point">
        <h3>Costs that rise on their own</h3>
        <p>In FY27, pay, benefits and mandatory costs rose {m(core_cost)} while tuition rate increases raised
        {m(v('v4_rates'))}. A 1% raise costs about {m(v('comp_base_fy27') * 0.01)}; a 1% increase in state
        funding brings about {m(one_pct_state)}. {tag('csu')} {tag('calc')}</p>
      </div>
    </div>
    <p>Both scenarios use the same starting gap, the same tuition increases, the same state funding and the same
    inflation. They differ in three things only: how the gap is closed, what happens to pay, and what happens
    to enrollment as a result. The third is the most uncertain and matters the most.</p>
  </div>
</section>

<section id="paths">
  <div class="wrap">
    <p class="secnum">2</p>
    <h2>The two paths</h2>
    <p class="answer">One spreads the pain thinly and indefinitely. The other concentrates it early and bets on a
    recovery.</p>
    <div class="scen-grid">{cards}</div>
    {gap_fig}
    {cum_fig}
  </div>
</section>

<section id="feel">
  <div class="wrap">
    <p class="secnum">3</p>
    <h2>What 2030 looks like</h2>
    <p class="answer">The dollar totals are closer than the experience of working or studying there.</p>
    <p class="fine">{tag('infer')} The descriptions below are the author's judgment about how each set of numbers
    would play out, informed by what has happened at other public universities facing similar gaps. They are
    not outputs of the arithmetic.</p>

    <div class="scen-grid">
      <article class="scen">
        <h3>{e(na)}</h3>
        <p class="scen-tag">Fall 2030</p>
        <ul>
          <li><strong>A fifth round of cuts is under way.</strong> The FY31 budget opened about
          {m(D['years'][-1]['gap'], 0)} short, and FY32 will too. Every budget year since FY27 has
          brought a new reduction target.</li>
          <li><strong>The cuts fell where they were easiest, not where they made sense.</strong> Roughly
          {n(r10(D['positions']))} positions are gone since 2026, mostly through vacancies, retirements and
          non-renewals. Which departments lost people depended on who happened to leave.</li>
          <li><strong>Almost everything still exists, thinner.</strong> The catalog looks much as it did. Many
          programs have too few faculty to offer required courses on schedule, so sections are larger and
          students take longer to finish.</li>
          <li><strong>Pay has fallen about {abs(D['real_pay']) * 100:.0f}% behind inflation.</strong> The people
          with the most options leave first, and searches to replace them are frozen.</li>
          <li><strong>Enrollment keeps sliding.</strong> Nonresident students number about
          {n(r100(D['nr_head']))}, down from {n(nr24)} in 2024. Each year's cuts make the next year's
          recruiting harder.</li>
          <li><strong>The balance sheet absorbs what the budget cannot.</strong> Covering a quarter of each
          gap with one-time money means drawing on reserves, and maintenance is the usual place to defer.</li>
        </ul>
        <p><strong>What this path has going for it:</strong> no single year forces a decision that cannot be
        undone, no program is closed in public, and if enrollment or state funding surprises on the upside,
        little has been given up. It is also the path every incentive favors, because each unit's rational
        response to a target is to protect itself.</p>
      </article>
      <article class="scen b">
        <h3>{e(nb)}</h3>
        <p class="scen-tag">Fall 2030</p>
        <ul>
          <li><strong>The worst year is three years behind.</strong> FY28 closed the whole {m(c['gap_fy28'], 0)}
          gap with permanent decisions: roughly {n(r10(first_year_pos_b))} positions in one year, compared with
          about {n(r10(first_year_pos_a))} under the other path. It included layoffs, and programs that many
          people cared about ended or merged.</li>
          <li><strong>CSU is smaller and built for the students it has.</strong> It plans around
          {n(r100(E['nr_head']))} nonresident students, not {n(nr24)}. Total positions eliminated since 2026 are
          roughly {n(r10(E['positions']))}, a similar order of magnitude to the other path.</li>
          <li><strong>Fewer programs, staffed to work.</strong> What remains can offer its courses on schedule.
          Administrative work that every college used to do separately is done once.</li>
          <li><strong>Raises are back to 3%.</strong> Pay ends about {abs(E['real_pay']) * 100:.0f}% behind
          inflation rather than {abs(D['real_pay']) * 100:.0f}%, and has kept pace since FY30.</li>
          <li><strong>The yearly gap is down to about {m(E['years'][-1]['gap'], 0)}.</strong> That is a size
          ordinary budgeting can handle, and no deferred one-time money is waiting to come due.</li>
          <li><strong>Some of it did not work.</strong> A plan this large will include consolidations that
          saved less than promised and new programs that did not fill.</li>
        </ul>
        <p><strong>What this path costs:</strong> a brutal first year, real harm to people who did nothing
        wrong, a fight over who decides, and bad headlines at exactly the moment CSU needs applicants. Program
        closures draw national attention and can deter the applicants a recovery depends on. It also requires leadership with
        the standing to carry it, at a time when the president's office is in transition.</p>
      </article>
    </div>
  </div>
</section>

<section id="caveats">
  <div class="wrap">
    <p class="secnum">4</p>
    <h2>Where this could be wrong</h2>
    <p class="answer">&ldquo;{nb}&rdquo; only comes out ahead if enrollment responds. If it does not, it is the
    more expensive path.</p>
    {figure(f"The same early decisions, if enrollment falls anyway",
            hbars([
                dict(label=na, value=D["cum"], color="c-a", value_label=f"about {m(r5(D['cum']), 0)}",
                     tip=f"{na}: {m(D['cum'], 0)} cumulative permanent reductions"),
                dict(label=nb, sub="enrollment stabilizes, as assumed", value=E["cum"], color="c-b",
                     value_label=f"about {m(r5(E['cum']), 0)}",
                     tip=f"{nb}: {m(E['cum'], 0)} cumulative permanent reductions"),
                dict(label=nb, sub="enrollment falls as in the other path", value=Fl["cum"], color="c-b",
                     value_label=f"about {m(r5(Fl['cum']), 0)}",
                     tip=f"{nb} with no enrollment response: {m(Fl['cum'], 0)} cumulative permanent reductions"),
            ], 230, cls="big"),
            f"Cumulative permanent reductions, FY27&ndash;FY31. The third bar keeps the early decisions and the 3% "
            f"raises but gives &ldquo;{nb}&rdquo; the same enrollment losses as &ldquo;{na}&rdquo; and no new "
            f"revenue. Paying competitive raises to a workforce sized for students who do not come costs about "
            f"{m(r5(Fl['cum'] - D['cum']), 0)} more than drifting. In practice the raises would be cut back, and "
            f"the two paths would converge.",
            ["scen"],
            "scenario arithmetic",
            details_table(["Case", "Cumulative permanent reductions", "Gap in FY31"],
                          [[na, m(D["cum"], 0), m(D["years"][-1]["gap"], 0)],
                           [nb + ", enrollment stabilizes", m(E["cum"], 0), m(E["years"][-1]["gap"], 0)],
                           [nb + ", enrollment falls anyway", m(Fl["cum"], 0), m(Fl["years"][-1]["gap"], 0)]]))}
    <ul class="unknowns">
      <li><strong>Enrollment is the whole question.</strong> The scenarios assume nonresident enrollment keeps
      falling 6% a year under one path and levels off under the other. Both are guesses. The demographic
      projections say the pool shrinks either way through 2041.</li>
      <li><strong>The arithmetic is simple on purpose.</strong> It carries forward FY27's cost increases and
      the ratio of positions to dollars from FY27's cuts. Real budgets have many more moving parts, and CSU has
      not published its FY28 line items.</li>
      <li><strong>Things left out.</strong> Federal research funding, a recession, the move to a new athletic
      conference, online enrollment, changes in state policy after the 2026 election, and the outcome of the
      Amendment 87 lawsuit could each move the result by tens of millions in either direction.</li>
      <li><strong>The two paths are ends of a range.</strong> A real response would mix them. The value of
      drawing the extremes is to see what each one trades away.</li>
      <li><strong>Who wrote the descriptions.</strong> The narrative in section 3 was drafted by an AI model
      under the author's direction. It reflects general patterns from other universities, not inside
      knowledge of CSU.</li>
    </ul>
  </div>
</section>

<section id="assumptions">
  <div class="wrap">
    <p class="secnum">5</p>
    <h2>Every assumption</h2>
    <p class="answer">Disagree with one? Change it in <code>data.py</code> and rebuild; the page recomputes.</p>
    {table(["Assumption", na, nb, "Basis"], assume_rows)}
    <p class="fine">How the arithmetic works. FY28 uses CSU's projected gap and assumes total tuition is level
    with FY27 (rate increases roughly offsetting the enrollment loss CSU has described). For each later year,
    the gap equals any one-time money used the year before, plus cost growth (raises on a payroll base of
    {m(v('comp_base_fy27'), 0)}, benefits, mandatory costs, financial aid, new investments), minus revenue
    growth (tuition rates and enrollment applied to FY27 tuition of {m(v('t_nr_fy27'))} nonresident and
    {m(v('t_res_fy27'))} resident, state funding of {m(v('state_total_fy27'))}, and any new revenue).
    Permanent cuts reduce the payroll base by 60% of their value. Positions are estimated at
    {PER_FTE:.1f} per $1M of permanent cuts, the FY27 ratio. Pay after inflation compounds each year's raise
    against 3% inflation. Sources for the inputs: {src("bdb", "obs_fy27", "forum_may13", "forum_jan15", "wiche", "cosun_cliff")}.</p>
  </div>
</section>
"""
    return page("CSU in 2030: two scenarios",
                "An illustrative look at Colorado State University in 2030 under two responses to its "
                "recurring budget gap. A thought experiment with stated assumptions, not a forecast.",
                body, "2030")


def write_csv():
    with open(os.path.join(HERE, "figures.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["id", "value", "unit", "description", "kind", "document", "publisher", "locator", "url"])
        for k, (val, unit, desc, sid, loc, kind) in F.items():
            s = SOURCES[sid]
            w.writerow([k, val, unit, desc, KIND_LABEL[kind], s["title"], s["publisher"], loc, s["url"]])


if __name__ == "__main__":
    with open(os.path.join(HERE, "index.html"), "w") as fh:
        fh.write(build_index())
    with open(os.path.join(HERE, "sources.html"), "w") as fh:
        fh.write(build_sources())
    with open(os.path.join(HERE, "csu-2030.html"), "w") as fh:
        fh.write(build_2030())
    write_csv()
    print("built index.html, csu-2030.html, sources.html, figures.csv")
    for k in ("drift", "decide", "decide_fail"):
        r = RESULTS[k]
        print("  ", k, [round(x["gap"], 1) for x in r["years"]], "cum", round(r["cum"], 1),
              "pos", round(r["positions"]), "nr", round(r["nr_head"]), "res", round(r["res_head"]),
              "pay", round(r["real_pay"], 3))
    print(f"  gap {gap_lo}-{gap_hi}; rest {rest_lo:.1f}-{rest_hi:.1f}; residual low {resid_lo:.1f}")
    print(f"  NR share of growth FY15-25 {nr_share_growth:.3f}; state share {state_share:.3f}; "
          f"tuition share {tuition_share:.3f}; NR share {nr_share_rev:.3f}")
    print(f"  per FTE: NR {nr_per_fte:,.0f} res {res_per_fte:,.0f} state/res {state_per_res:,.0f}")
    print(f"  cost growth {cost_growth:.3f} rev/student growth {rev_per_growth:.3f} cpi15-26 {cpi_15_26:.3f} cpi15-25 {cpi_15_25:.3f}")
    print(f"  state needed {state_needed_lo:.3f}-{state_needed_hi:.3f}; 1% {one_pct_state:.2f}; 3% {three_pct_state:.2f}")
    print(f"  NR headcount drop {nr_head_drop:.3f}; payouts {payouts}; ath support {ath_support:.3f} share {ath_support_fees_share:.3f}")
    print(f"  staffing: cdhe {cdhe_fte_growth:.3f} students {stu_growth_15_26:.3f}/{stu_growth_15_25:.3f} fb fac {fb_fac_growth:.3f} staff {fb_staff_growth:.3f}")
