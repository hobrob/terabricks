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
-- MAGIC Returns true if t occurs within the bounds of p, else returns false or null if p or t are null.

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
            if validPeriod.dttm_type != validInstant.dttm_type:
                raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
            return validPeriod.start_ts <= validInstant.instant_ts < validPeriod.end_ts:
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

$$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Contains')(array('2025-06-01', '2025-06-30'), '2025-06-15');



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Consumes(p1, p2)
-- MAGIC Returns true if p1 is at least equal to or fully engulfs p2, else returns false or null if p1 or p2 are null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Consumes')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type != validPeriod2.dttm_type:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
        return validPeriod1.start_ts <= validPeriod1.start_ts and validPeriod1.end_ts >= validPeriod1.end_ts
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

$$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Consumes')(array('2025-06-01', '2025-07-01'), array('2025-06-10', '2025-06-20'));



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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Begin')(array('2025-06-01', '2025-06-30'));

-- COMMAND ----------

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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.End')(array('2025-06-01', '2025-06-30'));

-- COMMAND ----------

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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Last')(array('2025-06-01', '2025-06-30'));



-- COMMAND ----------

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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Overlaps')(array('2025-06-01', '2025-06-30'), array('2025-06-15', '2025-07-15'));



-- COMMAND ----------

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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.OverlapsLeft')(array('2025-06-01', '2025-06-30'), array('2025-05-15', '2025-06-15'));



-- COMMAND ----------

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

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.OverlapsRight')(array('2025-06-01', '2025-06-30'), array('2025-06-15', '2025-07-15'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Next(t)
-- MAGIC Returns the date, time or timestamp that is a single unit of grain later than t. Returns null if t is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Next')(instant string)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    import math
    from datetime import timedelta

    from temporals.core.validators import validate_instant_string
    from temporals.core.utils import is_max_dttm
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if instant is None:
        return None
    validInstant = validate_instant_string(instant)
    if validInstant:
        if is_max_dttm(validInstant.instant_ts, validInstant.dttm_type, validInstant.precision):
            raise ValueError(ERRMSG[ERR_MAX_DATE])
        if validInstant.dttm_type == DATE:
            return str(validInstant.instant_ts + timedelta(days=1))
        elif validInstant.dttm_type == TIME:
            calendarised_end_ts = datetime.combine(datetime.today(), validInstant.instant_ts)
            if validInstant.precision == 0:
                return str((calendarised_end_ts + timedelta(seconds=1)).time())
            else:
                return str((calendarised_end_ts + timedelta(microseconds=(math.pow(10, 6 - validInstant.precision)))).time())
        elif validInstant.dttm_type == TIMESTAMP:
            if validInstant.precision == 0:
                return str(validInstant.instant_ts + timedelta(seconds=1))
            else:
                return str(validInstant.instant_ts + timedelta(microseconds=(math.pow(10, 6 - validInstant.precision))))
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Next')('2025-06-01');



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Prior(t)
-- MAGIC Returns the date, time or timestamp that is a single unit of grain earlier than t. Returns null if t is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Prior')(instant string)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    import math
    from datetime import timedelta

    from temporals.core.validators import validate_instant_string
    from temporals.core.utils import is_min_dttm
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if instant is None:
        return None
    validInstant = validate_instant_string(instant)
    if validInstant:
        if is_min_dttm(validInstant.instant_ts, validInstant.dttm_type):
            raise ValueError(ERRMSG[ERR_MIN_DATE])
        if validInstant.dttm_type == DATE:
            return str(validInstant.instant_ts - timedelta(days=1))
        elif validInstant.dttm_type == TIME:
            calendarised_end_ts = datetime.combine(datetime.today(), validInstant.instant_ts)
            if validInstant.precision == 0:
                return str((calendarised_end_ts - timedelta(seconds=1)).time())
            else:
                return str((calendarised_end_ts - timedelta(microseconds=(math.pow(10, 6 - validInstant.precision)))).time())
        elif validInstant.dttm_type == TIMESTAMP:
            if validInstant.precision == 0:
                return str(validInstant.instant_ts - timedelta(seconds=1))
            else:
                return str(validInstant.instant_ts - timedelta(microseconds=(math.pow(10, 6 - validInstant.precision))))
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Prior')('2025-06-01');



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### MeetsInstant(p, t)
-- MAGIC Returns true if instant t is either one grain of time earlier than the lower bound of p or equal to the upper bound of p. Returns null if either p or t is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.MeetsInstant')(period array<string>, instant string)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    import math
    from datetime import timedelta

    from temporals.core.validators import validate_period_array, validate_instant_string
    from temporals.core.utils import is_max_dttm
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_MAX_DATE, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if period is None or instant is None:
        return None
    validPeriod = validate_period_array(period)
    validInstant = validate_instant_string(instant)
    if validPeriod and validInstant:
        if validPeriod.dttm_type != validInstant.dttm_type:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
        elif is_max_dttm(validInstant.instant_ts, validInstant.dttm_type, validInstant.precision):
            raise ValueError(ERRMSG[ERR_MAX_DATE])
        elif validPeriod.end_ts == validInstant.instant_ts:
            return True
        else:
            if validInstant.dttm_type == DATE:
                return validPeriod.start_ts == validInstant.instant_ts + timedelta(days=1)
            elif validInstant.dttm_type == TIME:
                calendarised_period_start_ts = datetime.combine(datetime.today(), validPeriod.start_ts)
                calendarised_period_end_ts = datetime.combine(datetime.today(), validPeriod.end_ts)
                calendarised_instant_ts = datetime.combine(datetime.today(), validInstant.instant_ts)
                return calendarised_period_start_ts == calendarised_instant_ts + timedelta(microseconds=math.pow(10, 6 - validInstant.precision))
            elif validInstant.dttm_type == TIMESTAMP:
                return validPeriod.start_ts == validInstant.instant_ts + timedelta(microseconds=math.pow(10, 6 - validInstant.precision))
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.MeetsInstant')(array('2025-06-01', '2025-06-30'), '2025-06-30');



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### MeetsPeriod(p1, p2)
-- MAGIC Returns true if the upper bound of either p1 or p2 is equal to the lower bound of the other. Returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.MeetsPeriod')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type != validPeriod2.dttm_type:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
        if validPeriod1.end_ts == validPeriod2.start_ts or validPeriod1.start_ts == validPeriod2.end_ts:
            return True
        else:
            return False
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.MeetsPeriod')(array('2025-06-01', '2025-07-01'), array('2025-07-01', '2025-08-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### IntervalString(p, q)
-- MAGIC Returns a string representing the duration of p in a format that is castable to the interval type specified by q

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalString')(period array<string>, interval_qualifier string)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from dateutil.relativedelta import relativedelta

    from temporals.core.validators import validate_period_array, validate_instant_string
    from temporals.core.utils import is_max_dttm, format_second_precision
    from temporals.core.constants import ERRMSG, ERR_MAX_UBOUND, ERR_INVALID_QUAL, ERR_UNKNOWN, DATE, TIME, TIMESTAMP

    if period is None:
        return None
    validPeriod = validate_period_array(period)
    if validPeriod:
        if is_max_dttm(validPeriod.end_ts, validPeriod.dttm_type, validPeriod.precision) and validPeriod.dttm_type in (DATE, TIMESTAMP):
            raise ValueError(ERRMSG[ERR_MAX_UBOUND])
        if (
            (validPeriod.dttm_type == DATE and interval_qualifier not in ('Y', 'Y2M', 'MO', 'D')) or
            (validPeriod.dttm_type == TIME and interval_qualifier not in ('D2H', 'D2M', 'D2S', 'H', 'H2M', 'H2S', 'M', 'M2S', 'S'))):
            raise ValueError(ERRMSG[ERR_INVALID_QUAL])
        else:
            delta = relativedelta(validPeriod.end_ts, validPeriod.start_ts)
            if interval_qualifier == 'Y':
                return str(delta.years)
            elif interval_qualifier == 'Y2M':
                return str(delta.years)+'-'+str(delta.months)
            elif interval_qualifier == 'MO':
                return str((delta.years*12)+delta.months)
            elif interval_qualifier == 'D':
                if validPeriod.dttm_type == DATE:
                    return str((validPeriod.end_ts - validPeriod.start_ts).days)
                else:
                    return str((validPeriod.end_ts.date() - validPeriod.start_ts.date()).days)
            elif interval_qualifier == 'D2H':
                days = (validPeriod.end_ts.date() - validPeriod.start_ts.date()).days
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds() - (days * 86400)
                hours = int(secs // 3600)
                return str(days)+' '+str(hours)
            elif interval_qualifier == 'D2M':
                days = (validPeriod.end_ts.date() - validPeriod.start_ts.date()).days
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds() - (days * 86400)
                mins = int((secs % 3600) // 60)
                hours = int(secs // 3600)
                return str(days)+' '+str(hours)+':'+str(mins)
            elif interval_qualifier == 'D2S':
                days = (validPeriod.end_ts.date() - validPeriod.start_ts.date()).days
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds() - (days * 86400)
                mins = int((secs % 3600) // 60)
                hours = int(secs // 3600)
                secs = secs % 60
                return str(days)+' '+str(hours)+':'+str(mins)+':'+format_second_precision(secs, validPeriod.precision)
            elif interval_qualifier == 'H':
                return str(int((validPeriod.end_ts - validPeriod.start_ts).total_seconds() / 3600))
            elif interval_qualifier == 'H2M':
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds()
                mins = int((secs % 3600) // 60)
                hours = int(secs // 3600)
                return str(hours)+':'+str(mins)
            elif interval_qualifier == 'H2S':
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds()
                mins = int((secs % 3600) // 60)
                hours = int(secs // 3600)
                secs = secs % 60
                return str(hours)+':'+str(mins)+':'+format_second_precision(secs, validPeriod.precision)
            elif interval_qualifier == 'M':
                return str(int((validPeriod.end_ts - validPeriod.start_ts).total_seconds() / 60))
            elif interval_qualifier == 'M2S':
                secs = (validPeriod.end_ts - validPeriod.start_ts).total_seconds()
                mins = int(secs // 60)
                secs = secs % 60
                return str(mins)+':'+format_second_precision(secs, validPeriod.precision)
            elif interval_qualifier == 'S':
                if validPeriod.precision == 0:
                    return str(int((validPeriod.end_ts - validPeriod.start_ts).total_seconds()))
                else:
                    return str((validPeriod.end_ts - validPeriod.start_ts).total_seconds())

    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Interval*[<q>|<q_abbrv>]*(p)
-- MAGIC Two udfs exist for each interval type, one with a fully verbose interval qualifier in the function name and the second an abbreviated shorthand variation.
-- MAGIC The verbosely named udfs make a call to IntervalString, passing a hardcoded shorthand qualifier to indicate which interval format it expects the return string to be in. The shorthand-named udf simply calls the verbosely named version

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalYear')(period array<string>)
  RETURNS INTERVAL YEAR
    RETURN CAST(IntervalString(period, 'Y') AS INTERVAL YEAR);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalY')(period array<string>)
  RETURNS INTERVAL YEAR
    RETURN IntervalYear(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalYearToMonth')(period array<string>)
  RETURNS INTERVAL YEAR TO MONTH
    RETURN CAST(IntervalString(period, 'Y2M') AS INTERVAL YEAR TO MONTH);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalY2M')(period array<string>)
  RETURNS INTERVAL YEAR TO MONTH
    RETURN IntervalYearToMonth(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalMonth')(period array<string>)
  RETURNS INTERVAL MONTH
    RETURN CAST(IntervalString(period, 'MO') AS INTERVAL MONTH);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalMo')(period array<string>)
  RETURNS INTERVAL MONTH
    RETURN IntervalMonth(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalDay')(period array<string>)
  RETURNS INTERVAL DAY
    RETURN CAST(IntervalString(period, 'D') AS INTERVAL DAY);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalD')(period array<string>)
  RETURNS INTERVAL DAY
    RETURN IntervalDay(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalDayToHour')(period array<string>)
  RETURNS INTERVAL DAY TO HOUR
    RETURN CAST(IntervalString(period, 'D2H') AS INTERVAL DAY TO HOUR);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalD2H')(period array<string>)
  RETURNS INTERVAL DAY TO HOUR
    RETURN IntervalDayToHour(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalDayToMinute')(period array<string>)
  RETURNS INTERVAL DAY TO MINUTE
    RETURN CAST(IntervalString(period, 'D2M') AS INTERVAL DAY TO MINUTE);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalD2M')(period array<string>)
  RETURNS INTERVAL DAY TO MINUTE
    RETURN IntervalDayToMinute(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalDayToSecond')(period array<string>)
  RETURNS INTERVAL DAY TO SECOND
    RETURN CAST(IntervalString(period, 'D2S') AS INTERVAL DAY TO SECOND);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalD2S')(period array<string>)
  RETURNS INTERVAL DAY TO SECOND
    RETURN IntervalDayToSecond(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalHour')(period array<string>)
  RETURNS INTERVAL HOUR
    RETURN CAST(IntervalString(period, 'H') AS INTERVAL HOUR);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalH')(period array<string>)
  RETURNS INTERVAL HOUR
    RETURN IntervalHour(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalHourToMinute')(period array<string>)
  RETURNS INTERVAL HOUR TO MINUTE
    RETURN CAST(IntervalString(period, 'H2M') AS INTERVAL HOUR TO MINUTE);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalH2M')(period array<string>)
  RETURNS INTERVAL HOUR TO MINUTE
    RETURN IntervalHourToMinute(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalHourToSecond')(period array<string>)
  RETURNS INTERVAL HOUR TO SECOND
    RETURN CAST(IntervalString(period, 'H2S') AS INTERVAL HOUR TO SECOND);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalH2S')(period array<string>)
  RETURNS INTERVAL HOUR TO SECOND
    RETURN IntervalHourToSecond(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalMinute')(period array<string>)
  RETURNS INTERVAL MINUTE
    RETURN CAST(IntervalString(period, 'M') AS INTERVAL MINUTE);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalMi')(period array<string>)
  RETURNS INTERVAL MINUTE
    RETURN IntervalMinute(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalMinuteToSecond')(period array<string>)
  RETURNS INTERVAL MINUTE TO SECOND
    RETURN CAST(IntervalString(period, 'M2S') AS INTERVAL MINUTE TO SECOND);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalM2S')(period array<string>)
  RETURNS INTERVAL MINUTE TO SECOND
    RETURN IntervalMinuteToSecond(period);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalSecond')(period array<string>)
  RETURNS INTERVAL SECOND
    RETURN CAST(IntervalString(period, 'S') AS INTERVAL SECOND);

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IntervalS')(period array<string>)
  RETURNS INTERVAL SECOND
    RETURN IntervalSecond(period);



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### IsUntilChanged(p)
-- MAGIC Returns true if the upper bound of p is set to the highest possible date and/or time in the system - 9999-12-31 23:59:59.999999, else false, or null if p is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.IsUntilChanged')(period array<string>)
RETURNS STRING
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.utils import is_max_dttm
    from temporals.core.constants import ERRMSG, ERR_UNKNOWN

    if period is None:
        return None
    validPeriod = validate_period_array(period)
    if validPeriod:
        return is_max_dttm(validPeriod.end_ts, validPeriod.dttm_type, validPeriod.precision)
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.IsUntilChanged')(array('2025-06-01', '9999-12-31'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Equals(p1, p2)
-- MAGIC Returns true if the upper and lower bound of both p1 and p2 are equal, else false, or returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Equals')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.start_ts == validPeriod2.start_ts and validPeriod1.end_ts == validPeriod2.end_ts:
                    return True
                else:
                    return False
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Equals')(array('2025-06-01', '2025-07-01'), array('2025-06-01', '2025-07-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Precedes(p1, p2)
-- MAGIC Returns true if the upper bound of p1 is less than or equal to the lower bound of p2, else return false, or returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Precedes')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.end_ts <= validPeriod2.start_ts:
                    return True
                else:
                    return False
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Precedes')(array('2025-03-01', '2025-04-01'), array('2025-06-01', '2025-07-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### ImmediatelyPrecedes(p1, p2)
-- MAGIC Returns true if the upper bound of p1 is equal to the lower bound of p2, else return false, or returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.ImmediatelyPrecedes')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.end_ts == validPeriod2.start_ts:
                    return True
                else:
                    return False
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.ImmediatelyPrecedes')(array('2025-05-01', '2025-06-01'), array('2025-06-01', '2025-07-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Succeeds(p1, p2)
-- MAGIC Returns true if the lower bound of p1 is greater than or equal to the upper bound of p2, else return false, or returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.Succeeds')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.start_ts >= validPeriod2.end_ts:
                    return True
                else:
                    return False
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.Succeeds')(array('2025-03-01', '2025-04-01'), array('2025-06-01', '2025-07-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### ImmediatelySucceeds(p1, p2)
-- MAGIC Returns true if the lower bound of p1 is equal to the upper bound of p2, else return false, or returns null if either p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.ImmediatelySucceeds')(period1 array<string>, period2 array<string>)
RETURNS BOOLEAN
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.start_ts == validPeriod2.end_ts:
                    return True
                else:
                    return False
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.ImmediatelySucceeds')(array('2025-05-01', '2025-06-01'), array('2025-06-01', '2025-07-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### LDiff(p1, p2)
-- MAGIC Returns a period-compliant array representing the leftmost section of p1 that exists before the lower bound of p2, or returns null if the periods do not sufficiently overlap or p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.LDiff')(period1 array<string>, period2 array<string>)
RETURNS ARRAY<STRING>
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.utils import format_precision
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN, DATE, TIME

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.end_ts <= validPeriod2.start_ts or validPeriod1.start_ts >= validPeriod2.end_ts or validPeriod1.start_ts == validPeriod2.start_ts:
                    return None
                else:
                    if validPeriod1.dttm_type == DATE or (validPeriod1.dttm_type == TIME and validPeriod1.precision == 0):
                        return [str(validPeriod1.start_ts), str(validPeriod2.start_ts)]
                    else:
                        return [format_precision(validPeriod1.start_ts, validPeriod1.precision), format_precision(validPeriod2.start_ts, validPeriod1.precision)]
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.LDiff')(array('2025-05-01', '2025-07-01'), array('2025-06-01', '2025-08-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### RDiff(p1, p2)
-- MAGIC Returns a period-compliant array representing the rightmost section of p1 that exists after the upper bound of p2, or returns null if the periods do not sufficiently overlap or p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.RDiff')(period1 array<string>, period2 array<string>)
RETURNS ARRAY<STRING>
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.utils import format_precision
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN, DATE, TIME

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.start_ts >= validPeriod2.end_ts or validPeriod1.end_ts <= validPeriod2.start_ts or validPeriod2.end_ts == validPeriod1.end_ts:
                    return None
                else:
                    if validPeriod1.dttm_type == DATE or (validPeriod1.dttm_type == TIME and validPeriod1.precision == 0):
                        return [str(validPeriod1.end_ts), str(validPeriod2.end_ts)]
                    else:
                        return [format_precision(validPeriod1.end_ts, validPeriod1.precision), format_precision(validPeriod2.end_ts, validPeriod1.precision)]
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.RDiff')(array('2025-05-01', '2025-07-01'), array('2025-06-01', '2025-08-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### P_Intermediate(p1, p2)
-- MAGIC Returns a period-compliant array representing any gap between p1 and p2, or returns null if the periods overlap or p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.P_Intermediate')(period1 array<string>, period2 array<string>)
RETURNS ARRAY<STRING>
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.utils import format_precision
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN, DATE, TIME

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.end_ts <= validPeriod2.start_ts:
                    if validPeriod1.dttm_type == DATE or (validPeriod1.dttm_type == TIME and validPeriod1.precision == 0):
                        return [str(validPeriod1.end_ts), str(validPeriod2.start_ts)]
                    else:
                        return [format_precision(validPeriod1.end_ts, validPeriod1.precision), format_precision(validPeriod2.start_ts, validPeriod1.precision)]
                elif validPeriod1.start_ts >= validPeriod2.end_ts:
                    if validPeriod1.dttm_type == DATE or (validPeriod1.dttm_type == TIME and validPeriod1.precision == 0):
                        return [str(validPeriod2.end_ts), str(validPeriod1.start_ts)]
                    else:
                        return [format_precision(validPeriod2.end_ts, validPeriod1.precision), format_precision(validPeriod1.start_ts, validPeriod1.precision)]
                else:
                    return None
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.P_Intermediate')(array('2025-02-01', '2025-04-01'), array('2025-06-01', '2025-08-01'));



-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### P_Intersect(p1, p2)
-- MAGIC Returns a period-compliant array representing the overlap p1 and p2, or returns null if the periods do not overlap or p1 or p2 is null.

-- COMMAND ----------

CREATE OR REPLACE FUNCTION IDENTIFIER(:catalog_name||'.'||:schema_name||'.P_Intersect')(period1 array<string>, period2 array<string>)
RETURNS ARRAY<STRING>
LANGUAGE PYTHON
ENVIRONMENT (
  dependencies = '["__VOLUME__/__WHEEL__"]',
  environment_version = 'None'
)
AS $$

    from temporals.core.validators import validate_period_array
    from temporals.core.utils import format_precision
    from temporals.core.constants import ERRMSG, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UNKNOWN, DATE, TIME

    if period1 is None or period2 is None:
        return None
    validPeriod1 = validate_period_array(period1)
    validPeriod2 = validate_period_array(period2)
    if validPeriod1 and validPeriod2:
        if validPeriod1.dttm_type == validPeriod2.dttm_type:
            if validPeriod1.precision == validPeriod2.precision:
                if validPeriod1.end_ts <= validPeriod2.start_ts or validPeriod1.start_ts >= validPeriod2.end_ts:
                    return None
                else:
                    if validPeriod1.dttm_type == DATE or (validPeriod1.dttm_type == TIME and validPeriod1.precision == 0):
                        return [str(validPeriod2.start_ts), str(validPeriod1.end_ts)]
                    else:
                        return [format_precision(validPeriod2.start_ts, validPeriod1.precision), format_precision(validPeriod1.end_ts, validPeriod1.precision)]
            else:
                raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
        else:
            raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
    raise RuntimeError(ERRMSG[ERR_UNKNOWN])

  $$;

SELECT current_timestamp(), IDENTIFIER(:catalog_name||'.'||:schema_name||'.P_Intersect')(array('2025-05-01', '2025-07-01'), array('2025-06-01', '2025-08-01'));
