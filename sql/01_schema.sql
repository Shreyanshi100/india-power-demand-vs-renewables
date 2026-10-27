CREATE DATABASE IF NOT EXISTS energy_india;
USE energy_india;

CREATE TABLE dim_state (
  state_id   INT AUTO_INCREMENT PRIMARY KEY,
  state_name VARCHAR(60) NOT NULL UNIQUE,
  region     VARCHAR(20) NOT NULL
);

CREATE TABLE fact_consumption (
  state_id        INT NOT NULL,
  fiscal_year     VARCHAR(7) NOT NULL,
  consumption_gwh DECIMAL(12,2) NULL,
  PRIMARY KEY (state_id, fiscal_year),
  FOREIGN KEY (state_id) REFERENCES dim_state(state_id)
);

CREATE TABLE fact_re_capacity (
  state_id       INT PRIMARY KEY,
  small_hydro_mw DECIMAL(10,2),
  wind_mw        DECIMAL(10,2),
  bio_total_mw   DECIMAL(10,2),
  solar_mw       DECIMAL(10,2),
  total_re_mw    DECIMAL(10,2),
  FOREIGN KEY (state_id) REFERENCES dim_state(state_id)
);