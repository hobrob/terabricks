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

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Contains(p, t)
-- MAGIC Tests t to see if it occurs within the bounds of p, returns true or false.

-- COMMAND ----------

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

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Begin(p)
-- MAGIC Returns the inclusive lower bound of p.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Begin')(period array<string>)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN, TEMPRL, DATE, TIME, TIMESTAMP

    if period is None:
        return None
    validPeriod = validate_period_array(period)
    if validPeriod:
        if validPeriod.dttm_type == DATE:
            return validPeriod.start_ts.strftime(TEMPRL[DATE]["format"])
        elif validPeriod.dttm_type == TIME:
            if validPeriod.precision == 0:
                return validPeriod.start_ts.strftime(TEMPRL[TIME]["format"])
            else:
                return validPeriod.start_ts.strftime(TEMPRL[TIME]["format"]+'.%f')
        elif validPeriod.dttm_type == TIMESTAMP:
            if validPeriod.precision == 0:
                return validPeriod.start_ts.strftime(TEMPRL[TIMESTAMP]["format"])
            else:
                return validPeriod.start_ts.strftime(TEMPRL[TIMESTAMP]["format"]+'.%f')
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), funlib.Begin(array('2025-06-01', '2025-06-30'));

-- MAGIC %md
-- MAGIC ### End(p)
-- MAGIC Returns the exclusive upper bound of p.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.End')(period array<string>)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN, TEMPRL, DATE, TIME, TIMESTAMP

    if period is None:
        return None
    validPeriod = validate_period_array(period)
    if validPeriod:
        if validPeriod.dttm_type == DATE:
            return validPeriod.end_ts.strftime(TEMPRL[DATE]["format"])
        elif validPeriod.dttm_type == TIME:
            if validPeriod.precision == 0:
                return validPeriod.end_ts.strftime(TEMPRL[TIME]["format"])
            else:
                return validPeriod.end_ts.strftime(TEMPRL[TIME]["format"]+'.%f')
        elif validPeriod.dttm_type == TIMESTAMP:
            if validPeriod.precision == 0:
                return validPeriod.end_ts.strftime(TEMPRL[TIMESTAMP]["format"])
            else:
                return validPeriod.end_ts.strftime(TEMPRL[TIMESTAMP]["format"]+'.%f')
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), funlib.End(array('2025-06-01', '2025-06-30'));


-- MAGIC %md
-- MAGIC ### Last(p)
-- MAGIC Returns the inclusive upper bound of p.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Last')(period array<string>)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    import math
    from datetime import date, time, datetime, timedelta

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if period is None:
        return None
    validPeriod = validate_period_array(period)
    if validPeriod:
        if validPeriod.dttm_type == DATE:
            return validPeriod.end_ts - timedelta(days=1)
        elif validPeriod.dttm_type == TIME:
            calendarised_end_ts = datetime.combine(datetime.today(), validPeriod.end_ts)
            if validPeriod.precision == 0:
                return (calendarised_end_ts - timedelta(seconds=1)).time()
            else:
                return (calendarised_end_ts - timedelta(microseconds=(math.pow(10, 6 - validPeriod.precision)))).time()
        elif validPeriod.dttm_type == TIMESTAMP:
            if validPeriod.precision == 0:
                return validPeriod.end_ts - timedelta(seconds=1)
            else:
                return validPeriod.end_ts - timedelta(microseconds=(math.pow(10, 6 - validPeriod.precision)))
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;


-- MAGIC %md
-- MAGIC ### Overlaps(p1, p2)
-- MAGIC If p1 and p2 are both valid periods it returns true if p2 overlaps p1, else false. Returns null if either one of p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Overlaps')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        return validPeriod1.start_ts <= validPeriod2.end_ts and validPeriod2.start_ts < validPeriod1.end_ts
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;


-- MAGIC %md
-- MAGIC ### OverlapsLeft(p1, p2)
-- MAGIC If p1 and p2 are both valid periods it returns true if p2 overlaps p1 and the upper bound of p2 is less than or equal to the upper bound of p1, else false. Returns null if either one of p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.OverlapsLeft')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        return validPeriod1.start_ts <= validPeriod2.end_ts and validPeriod2.start_ts < validPeriod1.end_ts and validPeriod2.end_ts <= validPeriod1.end_ts
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

-- MAGIC %md
-- MAGIC ### OverlapsRight(p1, p2)
-- MAGIC If p1 and p2 are both valid periods it returns true if p2 overlaps p1 and the lower bound of p2 is greater than or equal to the lower bound of p1, else false. Returns null if either one of p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.OverlapsRight')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        return validPeriod1.start_ts <= validPeriod2.end_ts and validPeriod2.start_ts < validPeriod1.end_ts and validPeriod2.start_ts >= validPeriod1.start_ts
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

