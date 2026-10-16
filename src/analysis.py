"""Run every SQL file in sql/ against the Olist CSVs, save result tables and charts.

Usage (from repo root):  python src/analysis.py
"""
from pathlib import Path

import duckdb
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs"
OUT.mkdir(exist_ok=True)

con = duckdb.connect()
import os
os.chdir(ROOT)
con.execute((ROOT / "sql/00_setup.sql").read_text())

results = {}
for f in sorted((ROOT / "sql").glob("0[1-9]_*.sql")):
    df = con.execute(f.read_text()).df()
    df.to_csv(OUT / f"{f.stem}.csv", index=False)
    results[f.stem] = df
    print(f"{f.stem}: {len(df)} rows")

plt.rcParams.update({"figure.dpi": 140, "axes.spines.top": False, "axes.spines.right": False})

# 1. Monthly orders + GMV
k = results["01_monthly_kpis"]
fig, ax = plt.subplots(figsize=(9, 4))
ax.bar(k.purchase_month.dt.strftime("%Y-%m"), k.orders, color="#4C72B0")
ax.set_title("Monthly orders (Jan 2017 - Aug 2018)")
ax.set_ylabel("Orders")
plt.xticks(rotation=60, ha="right")
fig.tight_layout(); fig.savefig(OUT / "monthly_orders.png"); plt.close(fig)

# 2. Funnel
fn = results["02_fulfilment_funnel"]
fig, ax = plt.subplots(figsize=(7, 3.5))
ax.barh(fn.stage[::-1], fn.pct_of_placed[::-1], color="#55A868")
for i, v in enumerate(fn.pct_of_placed[::-1]):
    ax.text(v + 0.5, i, f"{v}%", va="center")
ax.set_xlim(0, 110); ax.set_title("Order lifecycle funnel (% of placed orders)")
fig.tight_layout(); fig.savefig(OUT / "funnel.png"); plt.close(fig)

# 3. Cohort heatmap
c = results["03_cohort_retention"]
piv = c.pivot(index="cohort_month", columns="month_n", values="retention_pct").sort_index()
piv.index = piv.index.strftime("%Y-%m")
piv = piv.drop(columns=0)
fig, ax = plt.subplots(figsize=(7, 7))
im = ax.imshow(piv.values, cmap="Blues", aspect="auto")
ax.set_xticks(range(piv.shape[1])); ax.set_xticklabels(piv.columns)
ax.set_yticks(range(piv.shape[0])); ax.set_yticklabels(piv.index, fontsize=7)
ax.set_xlabel("Months since first order"); ax.set_title("Repeat-purchase rate by cohort (%)")
fig.colorbar(im, ax=ax, shrink=0.7)
fig.tight_layout(); fig.savefig(OUT / "cohort_retention.png"); plt.close(fig)

# 4. Delivery vs reviews
d = results["05_delivery_vs_reviews"]
fig, ax = plt.subplots(figsize=(8, 3.8))
ax.bar(d.delivery_bucket.str[3:], d.avg_review, color="#C44E52")
ax.set_ylim(1, 5); ax.set_ylabel("Avg review score")
ax.set_title("Late delivery is the biggest driver of low reviews")
plt.xticks(rotation=20, ha="right")
fig.tight_layout(); fig.savefig(OUT / "delivery_vs_reviews.png"); plt.close(fig)
print("charts saved")
