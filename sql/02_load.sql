USE energy_india;

INSERT INTO dim_state (state_name, region)
SELECT DISTINCT state, region FROM stg_consumption;

INSERT INTO fact_consumption (state_id, fiscal_year, consumption_gwh)
SELECT d.state_id, s.fiscal_year, s.consumption_gwh
FROM stg_consumption s
JOIN dim_state d ON d.state_name = s.state;

INSERT INTO fact_re_capacity (state_id, small_hydro_mw, wind_mw, bio_total_mw, solar_mw, total_re_mw)
SELECT d.state_id, r.small_hydro_mw, r.wind_mw, r.bio_total_mw, r.solar_mw, r.total_re_mw
FROM stg_re_capacity r
JOIN dim_state d ON d.state_name = r.state;