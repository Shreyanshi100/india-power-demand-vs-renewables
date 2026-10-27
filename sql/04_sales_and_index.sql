USE energy_india;

CREATE TABLE fact_sales_category (
  state_id         INT PRIMARY KEY,
  commercial       DECIMAL(12,2),
  industrial_lv_mv DECIMAL(12,2),
  industrial_hv    DECIMAL(12,2),
  total_sold       DECIMAL(12,2),
  ci_gwh           DECIMAL(12,2),
  ci_share_pct     DECIMAL(6,2),
  FOREIGN KEY (state_id) REFERENCES dim_state(state_id)
);

INSERT INTO fact_sales_category
SELECT d.state_id, s.commercial, s.industrial_lv_mv, s.industrial_hv, s.total_sold, s.ci_gwh, s.ci_share_pct
FROM stg_sales_category s
JOIN dim_state d ON d.state_name = s.state;

SELECT COUNT(*) FROM fact_sales_category; 

CREATE OR REPLACE VIEW v_state_scores AS
WITH cagr AS (
  SELECT b.state_id,
         (POWER(l.consumption_gwh / b.consumption_gwh, 1.0 / 9) - 1) * 100 AS cagr_pct,
         l.consumption_gwh AS cons_2324
  FROM fact_consumption b
  JOIN fact_consumption l ON l.state_id = b.state_id AND l.fiscal_year = '2023-24'
  WHERE b.fiscal_year = '2014-15'),
metrics AS (
  SELECT s.state_id, s.state_name, s.region, x.ci_gwh, x.ci_share_pct, g.cagr_pct,
         (r.solar_mw + r.wind_mw) / (g.cons_2324 / 1000.0) AS var_re_mw_per_twh
  FROM dim_state s
  JOIN cagr g ON g.state_id = s.state_id
  JOIN fact_re_capacity r ON r.state_id = s.state_id
  JOIN fact_sales_category x ON x.state_id = s.state_id
  WHERE x.ci_gwh >= 5000)
SELECT state_id, state_name, region, ci_gwh, ci_share_pct, cagr_pct, var_re_mw_per_twh,
       PERCENT_RANK() OVER (ORDER BY ci_gwh)            AS score_size,
       PERCENT_RANK() OVER (ORDER BY ci_share_pct)      AS score_share,
       PERCENT_RANK() OVER (ORDER BY cagr_pct)          AS score_growth,
       PERCENT_RANK() OVER (ORDER BY var_re_mw_per_twh) AS score_re
FROM metrics;

SELECT COUNT(*) FROM v_state_scores;


CREATE TABLE weight_sets (
  set_name VARCHAR(20) PRIMARY KEY,
  w_size INT, w_share INT, w_growth INT, w_re INT
);
INSERT INTO weight_sets VALUES
  ('Default', 30, 20, 20, 30),
  ('Equal', 25, 25, 25, 25),
  ('Size-heavy', 50, 20, 10, 20),
  ('Growth-heavy', 20, 10, 50, 20),
  ('RE-heavy', 20, 10, 20, 50);

CREATE OR REPLACE VIEW v_scenario_ranks AS
SELECT w.set_name, v.state_name, v.region,
  ROUND((w.w_size * v.score_size + w.w_share * v.score_share
       + w.w_growth * v.score_growth + w.w_re * v.score_re)
       / (w.w_size + w.w_share + w.w_growth + w.w_re) * 100, 1) AS bess_score,
  RANK() OVER (PARTITION BY w.set_name ORDER BY
       (w.w_size * v.score_size + w.w_share * v.score_share
      + w.w_growth * v.score_growth + w.w_re * v.score_re) DESC) AS rank_in_set
FROM v_state_scores v
CROSS JOIN weight_sets w;



-- top 5 under each weight set
SELECT set_name, state_name, bess_score, rank_in_set
FROM v_scenario_ranks
WHERE rank_in_set <= 5
ORDER BY set_name, rank_in_set;

-- how often each state makes the top 5
SELECT state_name,
       SUM(rank_in_set <= 5) AS times_in_top5,
       MIN(rank_in_set) AS best_rank,
       MAX(rank_in_set) AS worst_rank
FROM v_scenario_ranks
GROUP BY state_name
HAVING times_in_top5 > 0
ORDER BY times_in_top5 DESC, best_rank;