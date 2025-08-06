-- Databricks notebook source
-- MAGIC %md
-- MAGIC ### IsPeriod(p)
-- MAGIC Tests p for being the structure of an array of two or more string elements, and that the first two elements can be cast to either a date, or a time or timestamp of matching precision, and that the upper bound is at least one unit grain of time greater than the lower bound.

-- COMMAND ----------

USE CATALOG IDENTIFIER(:catalog_name);
USE SCHEMA IDENTIFIER(:schema_name);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.SmokeTest')()
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__WHEEL_PATH__"]',
  environment_version = 'None'
)
AS $$

from temporals.core.validators import ping

return ping() == "pong"

$$;

SELECT current_timestamp(), funlib.SmokeTest();


sed "s|__WHEEL_PATH__|${WORKSPACE_VOLUME_PATH}/${WHEEL_NAME}|g" define_temporals_udf.sql > expanded.sql

