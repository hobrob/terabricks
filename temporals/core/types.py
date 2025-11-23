
from collections import namedtuple

PeriodInfo = namedtuple("PeriodInfo", ["start_ts", "end_ts", "dttm_type", "precision"])
InstantInfo = namedtuple("InstantInfo", ["instant_ts", "dttm_type", "precision"])
