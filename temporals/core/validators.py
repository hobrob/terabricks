
from typing import List
from datetime import datetime
import re

from temporals.core.utils import cast_str_to_dttm, get_dttm_precision
from temporals.core.types import PeriodInfo, InstantInfo
from temporals.core.constants import (
    TEMPRL, DT, TM, TS,
    ERRMSG, ERR_ARRAY_LEN, ERR_INVALID_DTTM, ERR_INVALID_FORMAT, ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UBOUND_LE_LBOUND)


def ping() -> str:
    return "pong"


def validate_period_array(period: List[str]) -> PeriodInfo:
    if isinstance(period, list) and len(period) >= 2:
        start_str, end_str = period[0], period[1]
        for dttm_code in (DT, TM, TS):
            regex = TEMPRL[dttm_code]["regex"]
            if re.match(regex, start_str) and (end_str is None or re.match(regex, end_str)):
                if end_str is not None and len(start_str) != len(end_str):
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

    return PeriodInfo(start_ts, end_ts, dttm_type, precision)


def validate_instant_string(instant_str: str, target_type: int | None = None, target_precision: int | None = None) -> InstantInfo:
    for dttm_code in (DT, TM, TS):
        if re.match(TEMPRL[dttm_code]["regex"], instant_str):
            if target_type is not None and target_type != dttm_code:
                raise ValueError(ERRMSG[ERR_TYPE_MISMATCH])
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
    return InstantInfo(instant_ts, dttm_type, precision)
