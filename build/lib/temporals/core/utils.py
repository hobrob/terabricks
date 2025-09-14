
from datetime import datetime, date, time, timedelta
import math

from temporals.core.constants import DT, TM, TS, TEMPRL


def coalesce(*args) -> any:
    return next((x for x in args if x is not None), None)


def cast_str_to_dttm(vl: str, tp: int) -> date | time | datetime:
    if tp == DT:
        return datetime.strptime(vl, TEMPRL[DT]["format"]).date()
    elif tp == TM:
        return datetime.strptime(vl, TEMPRL[TM]["format"]).time() if len(vl) == 8 else datetime.strptime(vl, TEMPRL[TM]["format"] + '.%f').time()
    elif tp == TS:
        return datetime.strptime(vl, TEMPRL[TS]["format"]) if len(vl) == 19 else datetime.strptime(vl, TEMPRL[TS]["format"] + '.%f')


def get_dttm_precision(start_str: str, end_str: str | None, tp: int) -> int:
    if tp == DT:
        return 0
    elif tp == TM:
        return 0 if max(len(start_str), len(coalesce(end_str, ''))) == 8 else max(len(start_str), len(coalesce(end_str, ''))) - 9
    elif tp == TS:
        return 0 if max(len(start_str), len(coalesce(end_str, ''))) == 19 else max(len(start_str), len(coalesce(end_str, ''))) - 20


def format_precision(ts: datetime, precision: int) -> str:
    if precision == 0:
        return str(ts)[:-7]
    else:
        return str(ts)[:-(6-precision)]


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
        return datetime.min
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
