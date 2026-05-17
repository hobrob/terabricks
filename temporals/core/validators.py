
from typing import List
from datetime import datetime
import re

from temporals.core.utils import cast_str_to_dttm, get_dttm_precision, strip_tz_suffix
from temporals.core.types import PeriodInfo, InstantInfo
from temporals.core.constants import (
    TEMPRL, DT, TM, TS, PERIOD_UUID,
    ERRMSG, ERR_ARRAY_LEN, ERR_INVALID_DTTM, ERR_INVALID_FORMAT, ERR_TYPE_MISMATCH,
    ERR_PRECISION_MISMATCH, ERR_UBOUND_LE_LBOUND, ERR_TZ_MISMATCH, ERR_INVALID_PERIOD_STRUCT)


def ping() -> str:
    return "pong"


def validate_period_array(period: List[str]) -> PeriodInfo:
    if isinstance(period, list) and len(period) >= 2:
        start_str, end_str = period[0], period[1]
        clean_start, start_tz = strip_tz_suffix(start_str)
        if end_str is not None:
            clean_end, end_tz = strip_tz_suffix(end_str)
            if start_tz != end_tz:
                raise ValueError(ERRMSG[ERR_TZ_MISMATCH])
        else:
            clean_end = None
        for dttm_code in (DT, TM, TS):
            regex = TEMPRL[dttm_code]["regex"]
            if re.match(regex, start_str) and (end_str is None or re.match(regex, end_str)):
                if end_str is not None and len(clean_start) != len(clean_end):
                    raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
                try:
                    start_ts = cast_str_to_dttm(start_str, dttm_code)
                    if end_str is not None:
                        end_ts = cast_str_to_dttm(end_str, dttm_code)
                        if end_ts <= start_ts:
                            raise ValueError(ERRMSG[ERR_UBOUND_LE_LBOUND])
                    else:
                        end_ts = (
                            datetime.max.date() if dttm_code == DT
                            else datetime.max.time() if dttm_code == TM
                            else datetime.max)
                    dttm_type = dttm_code
                    precision = get_dttm_precision(start_str, end_str, dttm_code)
                    break
                except ValueError as e:
                    if str(e) in ERRMSG.values():
                        raise e
                    else:
                        raise ValueError(ERRMSG[ERR_INVALID_DTTM])
        else:
            raise ValueError(ERRMSG[ERR_INVALID_FORMAT])
    else:
        raise ValueError(ERRMSG[ERR_ARRAY_LEN])

    return PeriodInfo(start_ts, end_ts, dttm_type, precision, start_tz)


def validate_instant_string(instant_str: str, target_type: int | None = None, target_precision: int | None = None, target_tz: str | None = None) -> InstantInfo:
    for dttm_code in (DT, TM, TS):
        if re.match(TEMPRL[dttm_code]["regex"], instant_str):
            if target_type is not None and target_type != dttm_code:
                raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
            _, instant_tz = strip_tz_suffix(instant_str)
            if target_tz is not None and target_tz != instant_tz:
                raise ValueError(ERRMSG[ERR_TZ_MISMATCH])
            try:
                instant_ts = cast_str_to_dttm(instant_str, dttm_code)
            except ValueError:
                raise ValueError(ERRMSG[ERR_INVALID_DTTM])
            dttm_type = dttm_code
            precision = get_dttm_precision(instant_str, None, dttm_code)
            break
    else:
        raise ValueError(ERRMSG[ERR_INVALID_FORMAT])
    if target_precision is not None and target_precision != precision:
        raise ValueError(ERRMSG[ERR_PRECISION_MISMATCH])
    return InstantInfo(instant_ts, dttm_type, precision, instant_tz)


def _get_struct_field(struct, field: str):
    """Return a field value from a Period struct regardless of whether it is a
    plain dict (unit tests) or a Databricks Row/namedtuple object (runtime)."""
    if isinstance(struct, dict):
        return struct.get(field)
    return getattr(struct, field, None)


def validate_period_struct(period_struct) -> PeriodInfo:
    """Fast validation using the UUID watermark embedded by the Period() constructor.

    Checks only for the presence of the watermark UUID instead of running the
    full regex + datetime validation performed by validate_period_array(). Use
    this in all UDFs that accept a Period struct to minimise per-row overhead
    at scale.
    """
    if period_struct is None:
        return None
    if _get_struct_field(period_struct, "period_id") != PERIOD_UUID:
        raise ValueError(ERRMSG[ERR_INVALID_PERIOD_STRUCT])
    lower = _get_struct_field(period_struct, "lower")
    upper = _get_struct_field(period_struct, "upper")
    # Quick type detection: dates are exactly 10 characters with hyphens at [4] and [7].
    # All other valid values are either TIME (HH:MM:… — colon at [2]) or TIMESTAMP.
    clean_lower, tz_offset = strip_tz_suffix(lower)
    if len(clean_lower) == 10 and clean_lower[4] == '-':
        dttm_type = DT
    elif len(clean_lower) > 2 and clean_lower[2] == ':':
        dttm_type = TM
    else:
        dttm_type = TS
    start_ts = cast_str_to_dttm(lower, dttm_type)
    end_ts = cast_str_to_dttm(upper, dttm_type)
    precision = get_dttm_precision(lower, upper, dttm_type)
    return PeriodInfo(start_ts, end_ts, dttm_type, precision, tz_offset)


def construct_period(lower: str, upper: str) -> dict:
    """Validate lower and upper bounds and return a Period struct dictionary.

    This is the backing implementation for the Period() SQL UDF constructor.
    Validation is performed once here; all subsequent UDF calls need only
    verify the embedded PERIOD_UUID watermark via validate_period_struct().
    """
    validate_period_array([lower, upper])
    return {"lower": lower, "upper": upper, "period_id": PERIOD_UUID}
