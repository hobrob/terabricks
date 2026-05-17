
from typing import NamedTuple


class PeriodInfo(NamedTuple):
    start_ts: object
    end_ts: object
    dttm_type: int
    precision: int
    tz_offset: str | None = None


class InstantInfo(NamedTuple):
    instant_ts: object
    dttm_type: int
    precision: int
    tz_offset: str | None = None
