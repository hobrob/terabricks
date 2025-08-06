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
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

from temporals.core.validators import ping

return ping() == "pong"

$$;

SELECT current_timestamp(), funlib.SmokeTest();



CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Contains')(period array<string>, instant string)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array, validate_instant_string
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN

    validPeriod = validate_period_array(period)
    if validPeriod:
        validInstant = validate_instant_string(instant, validPeriod.dttm_type, validPeriod.precision)
        if validInstant:
            if validPeriod.start_ts <= validInstant.instant_ts < validPeriod.end_ts:
                return True
            else:
                return False
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

$$;

SELECT current_timestamp(), funlib.Contains(array('2025-06-01', '2025-06-30'), '2025-06-15');




