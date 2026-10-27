SELECT s.state_name, c.fiscal_year, c.consumption_gwh,
  ROUND((c.consumption_gwh - LAG(c.consumption_gwh) OVER (PARTITION BY c.state_id ORDER BY c.fiscal_year))
        / LAG(c.consumption_gwh) OVER (PARTITION BY c.state_id ORDER BY c.fiscal_year) * 100, 2) AS yoy_pct
FROM fact_consumption c
JOIN dim_state s ON s.state_id = c.state_id
WHERE s.state_name = 'Rajasthan'
ORDER BY c.fiscal_year;
WITH base AS (
  SELECT state_id, consumption_gwh AS g0 FROM fact_consumption WHERE fiscal_year = '2014-15'),
latest AS (
  SELECT state_id, consumption_gwh AS g1 FROM fact_consumption WHERE fiscal_year = '2023-24'),
cagr AS (
  SELECT s.state_name, s.region, b.g0, l.g1,
         (POWER(l.g1 / b.g0, 1.0 / 9) - 1) * 100 AS cagr_pct
  FROM base b
  JOIN latest l   ON l.state_id = b.state_id
  JOIN dim_state s ON s.state_id = b.state_id)
SELECT region, state_name, ROUND(cagr_pct, 2) AS cagr_pct,
       RANK() OVER (PARTITION BY region ORDER BY cagr_pct DESC) AS rank_in_region
FROM cagr
ORDER BY region, rank_in_region;
SELECT s.state_name, c.consumption_gwh, r.total_re_mw,
       ROUND(r.total_re_mw / (c.consumption_gwh / 1000.0), 1) AS re_mw_per_twh,
       ROUND(r.solar_mw * 100.0 / r.total_re_mw, 1)            AS solar_share_pct
FROM fact_consumption c
JOIN dim_state s        ON s.state_id = c.state_id
JOIN fact_re_capacity r ON r.state_id = c.state_id
WHERE c.fiscal_year = '2023-24'
ORDER BY re_mw_per_twh DESC;
SELECT s.state_name, c.consumption_gwh,
       ROUND(c.consumption_gwh * 100 / SUM(c.consumption_gwh) OVER (), 1) AS share_of_india_pct
FROM fact_consumption c
JOIN dim_state s ON s.state_id = c.state_id
WHERE c.fiscal_year = '2023-24'
ORDER BY share_of_india_pct DESC;