
import pytest
from temporals.core.validators import validate_period_array
from temporals.core.types import PeriodInfo
from temporals.core.constants import DT, TM, TS, ERRMSG, ERR_ARRAY_LEN, ERR_INVALID_FORMAT, ERR_PRECISION_MISMATCH


def test_valid_date_period():
    period = ["2024-01-01", "2024-12-31"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == DT
    assert result.precision == 0
    assert result.start_ts.isoformat() == "2024-01-01"
    assert result.end_ts.isoformat() == "2024-12-31"


def test_valid_time_period():
    period = ["12:15:00", "12:30:00"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == TM
    assert result.precision == 0
    assert result.start_ts.isoformat() == "12:15:00"
    assert result.end_ts.isoformat() == "12:30:00"


def test_valid_timestamp_period():
    period = ["2024-01-01 12:15:00.123", "2024-12-31 12:30:00.456"]
    result = validate_period_array(period)
    assert isinstance(result, PeriodInfo)
    assert result.dttm_type == TS
    assert result.precision == 3
    assert result.start_ts.isoformat() == "2024-01-01T12:15:00.123000"
    assert result.end_ts.isoformat() == "2024-12-31T12:30:00.456000"


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
