# Which Indian States Make the Strongest Case for C&I Battery Storage?

A state-level scoring index built from Central Electricity Authority (CEA) data, with an interactive Power BI dashboard and a sensitivity analysis that tests how much the ranking depends on the weights.

**Tools:** Python (pdfplumber, pandas, SQLAlchemy) · MySQL 8 · Power BI Desktop

---

## Summary

The CEA's *All India Electricity Statistics, General Review 2025* publishes state-wise figures only as tables inside a 198-page PDF. I extracted three of those tables with Python, validated them against the totals printed in the report, loaded them into a MySQL star schema, and built a weighted index that ranks states on how attractive they look for **commercial and industrial (C&I) battery energy storage**. The Power BI dashboard lets a viewer change the weights with sliders and see the ranking update, and a separate page shows which results hold up under five different weight sets.

**Main finding:** Gujarat ranks first under every weight set tested (average rank 1.0). Rajasthan stays between 2nd and 4th (average 3.2). Maharashtra and Tamil Nadu rank high on scale but fall to 8th and 13th when growth carries half the weight, so positions three to five depend on how much a decision-maker values growth against current scale.

## The question

> Which Indian states offer the strongest case for C&I battery storage, based on market size, C&I share of sales, demand growth and renewable penetration, and how stable is that ranking when the weights change?

## Dashboard

| Page | What it shows |
|---|---|
| National Overview | All-India consumption and renewable capacity, demand over time by region |
| State Explorer | Top 10 states by demand growth, with consumption and renewable capacity by state |
| Demand growth vs renewable readiness | Scatter of demand growth against renewable capacity relative to demand |
| BESS Ranking | Interactive ranking: four weight sliders re-rank the states live |
| Stability | Rank of each state under five weight sets, plus average rank |

Screenshots (replace the file names with yours):

![National Overview](images/page1_national_overview.png)
![State Explorer](images/page2_state_explorer.png)
![Demand growth vs renewable readiness](images/page3_demand_vs_renewables.png)
![BESS Ranking](images/page4_bess_ranking.png)
![Stability](images/page5_stability.png)

## Data

**Source:** Central Electricity Authority, *All India Electricity Statistics, General Review 2025* (data for FY2023-24). Source link: ADD LINK. The PDF is not included in this repository.

| Table | Content | PDF page |
|---|---|---|
| 1.7 | State-wise electricity consumption, 2012-13 to 2023-24 (GWh) | 32 |
| 3.11 | State-wise installed renewable capacity by source, as on 31.03.2024 (MW) | 66 |
| 9.3 | Electrical energy sales by consumer category and state, 2023-24 (GWh) | 139-140 |

## Method

1. **Extract** the three tables from the PDF with `pdfplumber`.
2. **Clean and validate** in pandas (see the decisions below). Every table is reconciled against the sub-totals and totals printed in the report.
3. **Load** into MySQL as a small star schema: `dim_state`, `fact_consumption`, `fact_re_capacity`, `fact_sales_category`.
4. **Analyse** with SQL: window functions (`LAG`, `RANK`, `PERCENT_RANK`), CTEs, a scoring view and a scenario view.
5. **Visualise** in Power BI with What-if parameters for the weights.

### Data issues and the decisions I made

| Issue in the source | Decision |
|---|---|
| Dadra & Nagar Haveli and Daman & Diu merged into one UT in 2020; the PDF prints the earlier years on two unlabelled lines | Added the two lines together and treated them as one UT for all years (the combined series is smooth into 2022-23) |
| Andhra Pradesh and Telangana split in 2014; AP's first two years include Telangana | Kept the two undivided years for AP, left Telangana empty for them, and started all growth calculations at 2014-15 |
| Table 3.11 lists Ladakh separately; Tables 1.7 and 9.3 combine it with Jammu & Kashmir | Added Ladakh's renewable capacity to Jammu & Kashmir |
| Table 3.11 has an "Others" row (about 49 MW) that cannot be assigned to a state | Dropped it |
| Inconsistent spellings across tables (Orissa, Madhay Pradesh, A & N Islands, and others) | Standardised to one spelling per state before any join |
| Footnote marker "$" on Jharkhand and West Bengal in Table 9.3 | Stripped from the names |

**Validation:** states add up to the printed regional sub-totals in Tables 1.7 and 9.3 (largest gap 0.03 GWh, from rounding), the renewable capacity columns add up to the printed totals in Table 3.11, and in Table 9.3 the categories add up to total energy sold.

## Scoring method

Each state is scored from 0 to 1 on four factors, using its **percentile rank** among the eligible states. Percentile ranks stop one extreme value, such as Bihar's 16.7% annual growth, from dominating.

| Factor | Definition |
|---|---|
| Market size | C&I sales in 2023-24 (GWh) |
| C&I share | C&I sales as a percentage of the state's total sales |
| Demand growth | Compound annual growth of consumption, 2014-15 to 2023-24 |
| Variable renewables | (Solar + wind capacity in MW) per TWh of consumption, a proxy for balancing need |

- **C&I definition:** Commercial + Industrial (low and medium voltage) + Industrial (high voltage) utility sales.
- **Eligibility screen:** only states with at least 5,000 GWh of C&I sales are scored (21 of 35 states and UTs). Ratios on a very small base are unstable.
- **Score:** weighted average of the four percentile scores, scaled to 100.

### Weight sets

| Set | Size | C&I share | Growth | Renewables |
|---|---|---|---|---|
| Default | 30 | 20 | 20 | 30 |
| Equal | 25 | 25 | 25 | 25 |
| Size-heavy | 50 | 20 | 10 | 20 |
| Growth-heavy | 20 | 10 | 50 | 20 |
| RE-heavy | 20 | 10 | 20 | 50 |

## Results

Under the default weights the top five are Gujarat (90.5), Maharashtra (69.5), Rajasthan (68.5), Tamil Nadu (68.5) and Andhra Pradesh (62.0). Percentile scores produce ties, which is why Rajasthan and Tamil Nadu share a score.

Rank of each state under each weight set (1 = best), for states that reach the top five at least once:

| State | Default | Equal | Growth-heavy | RE-heavy | Size-heavy | Average rank |
|---|---|---|---|---|---|---|
| Gujarat | 1 | 1 | 1 | 1 | 1 | 1.0 |
| Rajasthan | 3 | 3 | 4 | 2 | 4 | 3.2 |
| Maharashtra | 2 | 2 | 8 | 4 | 2 | 3.6 |
| Tamil Nadu | 3 | 3 | 13 | 3 | 3 | 5.0 |
| Telangana | 6 | 5 | 2 | 6 | 7 | 5.2 |
| Andhra Pradesh | 5 | 6 | 9 | 5 | 5 | 6.0 |
| Chhattisgarh | 9 | 7 | 3 | 9 | 15 | 8.6 |
| Uttar Pradesh | 9 | 12 | 5 | 10 | 8 | 8.8 |

**Takeaways**

- Gujarat has the largest C&I sales of any state (about 84,700 GWh, 65.8% of its consumption) and ranks first under every weight set.
- Rajasthan is the most consistent runner-up, helped by its renewable capacity relative to demand (about 26,700 MW, mostly solar).
- Maharashtra and Tamil Nadu are strong when scale matters but drop sharply when growth is weighted heavily.
- Chhattisgarh and Uttar Pradesh reach the top five only in the growth-heavy set, and Telangana only in the growth-heavy and equal-weight sets.

Context from the underlying data: all-India consumption grew from 708,843 GWh in 2012-13 to 1,350,092 GWh in 2023-24; Bihar had the fastest demand growth from 2014-15 (about 16.7% a year); Maharashtra is the largest consumer (12.4% of India).

## Limitations

- C&I here means utility sales to commercial and industrial customers. Open-access and captive power are not in this table.
- The index does not include tariffs, time-of-day pricing, grid constraints or state storage policy. It is a **screening tool, not a business case**.
- The weights are a judgement, and percentile ranks hide how large the gaps between states are.
- "Variable renewables per TWh" is a proxy for balancing need, not a measurement of it.
- Capacity is not generation, and the renewable capacity figure excludes large hydro.
- All data is a FY2023-24 snapshot.

## Repository structure

```
notebooks/   01_extract_cea_tables, 02_load_to_mysql
sql/         01_schema, 02_load, 03_analysis, 04_sales_and_index
data/clean/  consumption_clean.csv, re_capacity_clean.csv, sales_category_clean.csv
powerbi/     energy_dashboard.pbix
images/      dashboard screenshots
```

## How to reproduce

1. Download the CEA report and save it as `data/raw/All_India_Electricity_Statistics.pdf`.
2. Install Python with `pdfplumber`, `pandas`, `sqlalchemy`, `pymysql`, and install MySQL 8.0 or later (window functions need it).
3. Run notebook `01_extract_cea_tables` to create the three clean CSV files.
4. Run `sql/01_schema.sql`, then notebook `02_load_to_mysql` (enter your own MySQL password in the connection string), then `sql/02_load.sql`, `sql/04_sales_and_index.sql` and `sql/03_analysis.sql`.
5. Open `powerbi/energy_dashboard.pbix` and refresh it against your MySQL database.

## Possible next steps

- Add state-wise generation (Table 4.3) to compare installed capacity with actual generation.
- Add per-capita consumption (Table 9.9) as another factor.
- Layer in tariff structure and state storage policy, which are the biggest gaps in this index.
- Summarise findings automatically with an LLM step.

## Author

Shreyanshi Pandey · [LinkedIn](https://linkedin.com/in/shreyanshi-pandey-626008261/) · [GitHub](https://github.com/Shreyanshi100)
