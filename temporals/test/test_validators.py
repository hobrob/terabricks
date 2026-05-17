
import pytest
from temporals.core.validators import validate_period_array, validate_period_struct, construct_period
from temporals.core.types import PeriodInfo
from temporals.core.constants import (
    DT, TM, TS, PERIOD_UUID,
    ERRMSG, ERR_ARRAY_LEN, ERR_INVALID_FORMAT, ERR_PRECISION_MISMATCH,
    ERR_UBOUND_LE_LBOUND, ERR_TZ_MISMATCH, ERR_INVALID_PERIOD_STRUCT)


def test_valid_date_period():
    period = ["2024-01-01", "2024-12-31"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == DT
    assert result.precision == 0
    assert result.start_ts.isoformat() == "2024-01-01"
    assert result.end_ts.isoformat() == "2024-12-31"
    assert result.tz_offset is None


def test_valid_time_period():
    period = ["12:15:00", "12:30:00"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == TM
    assert result.precision == 0
    assert result.start_ts.isoformat() == "12:15:00"
    assert result.end_ts.isoformat() == "12:30:00"
    assert result.tz_offset is None


def test_valid_timestamp_period():
    period = ["2024-01-01 12:15:00.123", "2024-12-31 12:30:00.456"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == TS
    assert result.precision == 3
    assert result.start_ts.isoformat() == "2024-01-01T12:15:00.123000"
    assert result.end_ts.isoformat() == "2024-12-31T12:30:00.456000"
    assert result.tz_offset is None


def test_invalid_format_mixed_types():
    period = ["2024-01-01", "12:30:00"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_INVALID_FORMAT] in str(excinfo.value)


def test_invalid_format_mixed_precision():
    period = ["12:15:00.12", "12:30:00.3456"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_PRECISION_MISMATCH] in str(excinfo.value)


def test_array_too_short():
    period = ["2024-01-01"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_ARRAY_LEN] in str(excinfo.value)


def test_array_ubound_le_lbound():
    period = ["2024-01-01", "2024-01-01"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_UBOUND_LE_LBOUND] in str(excinfo.value)


# --- Timezone tests ---

def test_valid_timestamp_period_with_timezone():
    period = ["2024-01-01 12:15:00+05:30", "2024-12-31 12:30:00+05:30"]
    result = validate_period_array(period)
    assert result.dttm_type == TS
    assert result.precision == 0
    assert result.tz_offset == "+05:30"
    assert result.start_ts.isoformat() == "2024-01-01T12:15:00"
    assert result.end_ts.isoformat() == "2024-12-31T12:30:00"


def test_valid_time_period_with_timezone():
    period = ["12:15:00-04:00", "13:00:00-04:00"]
    result = validate_period_array(period)
    assert result.dttm_type == TM
    assert result.precision == 0
    assert result.tz_offset == "-04:00"


def test_valid_timestamp_period_with_utc():
    period = ["2024-06-01 08:00:00Z", "2024-06-30 08:00:00Z"]
    result = validate_period_array(period)
    assert result.dttm_type == TS
    assert result.tz_offset == "Z"


def test_timezone_mismatch_raises():
    period = ["2024-01-01 12:00:00+05:30", "2024-12-31 12:00:00-04:00"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_TZ_MISMATCH] in str(excinfo.value)


def test_mixed_tz_and_no_tz_raises():
    period = ["2024-01-01 12:00:00+05:30", "2024-12-31 12:00:00"]
    with pytest.raises(ValueError) as excinfo:
        validate_period_array(period)
    assert ERRMSG[ERR_TZ_MISMATCH] in str(excinfo.value)


# --- Period struct / constructor tests ---

def test_construct_period_returns_valid_struct():
    result = construct_period("2024-01-01", "2024-12-31")
    assert result["lower"] == "2024-01-01"
    assert result["upper"] == "2024-12-31"
    assert result["period_id"] == PERIOD_UUID


def test_construct_period_validates_inputs():
    with pytest.raises(ValueError) as excinfo:
        construct_period("2024-01-01", "2024-01-01")
    assert ERRMSG[ERR_UBOUND_LE_LBOUND] in str(excinfo.value)


def test_validate_period_struct_date():
    struct = {"lower": "2024-01-01", "upper": "2024-12-31", "period_id": PERIOD_UUID}
    result = validate_period_struct(struct)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == DT
    assert result.precision == 0
    assert result.start_ts.isoformat() == "2024-01-01"
    assert result.end_ts.isoformat() == "2024-12-31"


def test_validate_period_struct_timestamp():
    struct = {"lower": "2024-06-01 12:00:00.123", "upper": "2024-06-30 18:00:00.456", "period_id": PERIOD_UUID}
    result = validate_period_struct(struct)
    assert result.dttm_type == TS
    assert result.precision == 3


def test_validate_period_struct_time():
    struct = {"lower": "08:00:00", "upper": "17:00:00", "period_id": PERIOD_UUID}
    result = validate_period_struct(struct)
    assert result.dttm_type == TM


def test_validate_period_struct_with_timezone():
    struct = {"lower": "2024-06-01 08:00:00+01:00", "upper": "2024-06-30 08:00:00+01:00", "period_id": PERIOD_UUID}
    result = validate_period_struct(struct)
    assert result.dttm_type == TS
    assert result.tz_offset == "+01:00"


def test_validate_period_struct_wrong_uuid_raises():
    struct = {"lower": "2024-01-01", "upper": "2024-12-31", "period_id": "not-a-valid-uuid"}
    with pytest.raises(ValueError) as excinfo:
        validate_period_struct(struct)
    assert ERRMSG[ERR_INVALID_PERIOD_STRUCT] in str(excinfo.value)


def test_validate_period_struct_missing_uuid_raises():
    struct = {"lower": "2024-01-01", "upper": "2024-12-31"}
    with pytest.raises(ValueError) as excinfo:
        validate_period_struct(struct)
    assert ERRMSG[ERR_INVALID_PERIOD_STRUCT] in str(excinfo.value)


def test_validate_period_struct_none_returns_none():
    assert validate_period_struct(None) is None
