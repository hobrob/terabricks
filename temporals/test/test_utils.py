
from temporals.core.utils import *


def test_cast_date():
    assert cast_str_to_dttm("2024-01-01", DT) == date(2024, 1, 1)


def test_cast_time():
    assert cast_str_to_dttm("17:43:12", TM) == time(17, 43, 12)


def test_cast_time_with_microseconds():
    tm = cast_str_to_dttm("17:43:12.123456", TM)
    assert tm == time(17, 43, 12, 123456)
    assert tm.microsecond == 123456


def test_cast_timestamp_with_microseconds():
    ts = cast_str_to_dttm("2024-01-01 12:00:00.123456", TS)
    assert isinstance(ts, datetime)
    assert ts.microsecond == 123456


def test_time_precision_detection():
    precision = get_dttm_precision("12:30:15", None, TM)
    assert precision == 0
    precision = get_dttm_precision("12:30:15.999", None, TM)
    assert precision == 3
    precision = get_dttm_precision("12:30:15.999000", None, TM)
    assert precision == 6


def test_max_date_detection():
    assert is_max_dttm(date.max, DT, 0) is True
    assert is_max_dttm(date(9999, 12, 30), DT, 0) is False


def test_max_time_with_padding():
    max_t = time(23, 59, 59, 990000)
    assert is_max_dttm(max_t, TM, 3) is False
    max_t = time(23, 59, 59, 999000)
    assert is_max_dttm(max_t, TM, 3) is True


def test_max_timestamp():
    ts = datetime.max - timedelta(microseconds=0)
    assert is_max_dttm(ts, TS, 6) is True


# --- Timezone utility tests ---

def test_strip_tz_suffix_no_tz():
    base, tz = strip_tz_suffix("2024-01-01 12:00:00")
    assert base == "2024-01-01 12:00:00"
    assert tz is None


def test_strip_tz_suffix_positive_offset():
    base, tz = strip_tz_suffix("2024-01-01 12:00:00+05:30")
    assert base == "2024-01-01 12:00:00"
    assert tz == "+05:30"


def test_strip_tz_suffix_negative_offset():
    base, tz = strip_tz_suffix("12:00:00-04:00")
    assert base == "12:00:00"
    assert tz == "-04:00"


def test_strip_tz_suffix_utc():
    base, tz = strip_tz_suffix("2024-01-01 12:00:00Z")
    assert base == "2024-01-01 12:00:00"
    assert tz == "Z"


def test_cast_timestamp_with_tz_strips_tz():
    ts = cast_str_to_dttm("2024-06-15 09:30:00+05:30", TS)
    assert isinstance(ts, datetime)
    assert ts.hour == 9
    assert ts.minute == 30
    assert ts.tzinfo is None


def test_precision_detection_ignores_tz():
    precision = get_dttm_precision("12:30:15.999+05:30", None, TM)
    assert precision == 3
    precision = get_dttm_precision("2024-01-01 12:30:15.123456-04:00", None, TS)
    assert precision == 6


def test_format_precision_with_tz():
    ts = datetime(2024, 6, 1, 12, 0, 0, 123000)
    result = format_precision(ts, 3, "+05:30")
    assert result.endswith("+05:30")
    assert "12:00:00.123" in result
