
from datetime import datetime, date, time, timedelta
import math
import re

from temporals.core.constants import DT, TM, TS, TEMPRL

_TZ_PATTERN = re.compile(r"([+-]\d{2}:\d{2}|Z)$")


def coalesce(*args) -> any:
    return next((x for x in args if x is not None), None)


def strip_tz_suffix(s: str) -> tuple[str, str | None]:
    """Split a datetime string into its base value and optional timezone suffix.

    Returns a tuple of (base_string, tz_suffix) where tz_suffix is a string
    such as '+05:30', '-04:00', or 'Z', or None if no timezone was present.
    """
    match = _TZ_PATTERN.search(s)
    if match:
        return s[:match.start()], match.group(1)
    return s, None


def cast_str_to_dttm(vl: str, tp: int) -> date | time | datetime:
    clean_vl, _ = strip_tz_suffix(vl)
    if tp == DT:
        return datetime.strptime(clean_vl, TEMPRL[DT]["format"]).date()
    elif tp == TM:
        return datetime.strptime(clean_vl, TEMPRL[TM]["format"]).time() if len(clean_vl) == 8 else datetime.strptime(clean_vl, TEMPRL[TM]["format"] + '.%f').time()
    elif tp == TS:
        return datetime.strptime(clean_vl, TEMPRL[TS]["format"]) if len(clean_vl) == 19 else datetime.strptime(clean_vl, TEMPRL[TS]["format"] + '.%f')


def get_dttm_precision(start_str: str, end_str: str | None, tp: int) -> int:
    clean_start, _ = strip_tz_suffix(start_str)
    clean_end, _ = strip_tz_suffix(end_str) if end_str is not None else (None, None)
    if tp == DT:
        return 0
    elif tp == TM:
        return 0 if max(len(clean_start), len(coalesce(clean_end, ''))) == 8 else max(len(clean_start), len(coalesce(clean_end, ''))) - 9
    elif tp == TS:
        return 0 if max(len(clean_start), len(coalesce(clean_end, ''))) == 19 else max(len(clean_start), len(coalesce(clean_end, ''))) - 20


def format_precision(ts: datetime, precision: int, tz_offset: str | None = None) -> str:
    if precision == 0:
        result = str(ts)[:-7]
    else:
        result = str(ts)[:-(6-precision)]
    if tz_offset:
        result += tz_offset
    return result


def format_second_precision(secs: float, precision: int) -> str:
    if precision == 0:
        return str(int(secs))
    else:
        return format(secs, "."+str(precision)+"f")


def is_min_dttm(instant_ts: date | time | datetime, dttm_type: int) -> bool:
    if dttm_type == DT:
        return instant_ts == date.min
    elif dttm_type == TM:
        return instant_ts == datetime.min.time()
    elif dttm_type == TS:
        return instant_ts == datetime.min
    return False


def is_max_dttm(instant_ts: date | time | datetime, dttm_type: int, precision: int) -> bool:
    if dttm_type == DT:
        return instant_ts == date.max
    elif dttm_type == TM:
        if instant_ts == datetime.max.time():
            return True
        base_dt = datetime.combine(date.min, instant_ts)
        if precision == 6:
            return False
        else:
            precision_padding = int(math.pow(10, 6 - precision)) - 1
            padded_dt = base_dt + timedelta(microseconds=precision_padding)
        return padded_dt.time() == datetime.max.time()
    elif dttm_type == TS:
        if instant_ts == datetime.max:
            return True
        if precision == 6:
            return False
        else:
            precision_padding = int(math.pow(10, 6 - precision)) - 1
            padded_dt = instant_ts + timedelta(microseconds=precision_padding)
        return padded_dt == datetime.max
    return False
