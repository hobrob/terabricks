
DT, TM, TS = range(3)
DATE, TIME, TIMESTAMP = DT, TM, TS

# Fixed UUID watermark embedded by the Period() constructor.
# Any UDF receiving a Period struct can validate authenticity with a single
# equality check against this constant instead of re-running full validation.
PERIOD_UUID = "7b1f4b2e-9c3d-4f5a-8e6b-1a2c3d4e5f60"

TEMPRL = {
    DT: {"keyword": "DATE", "regex": r"^\d{4}-\d{2}-\d{2}$", "format": "%Y-%m-%d"},
    TM: {"keyword": "TIME", "regex": r"^\d{2}:\d{2}:\d{2}(\.\d{1,6})?([+-]\d{2}:\d{2}|Z)?$", "format": "%H:%M:%S"},
    TS: {"keyword": "TIMESTAMP", "regex": r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{1,6})?([+-]\d{2}:\d{2}|Z)?$", "format": "%Y-%m-%d %H:%M:%S"}}

ERR_ARRAY_LEN, ERR_INVALID_DTTM, ERR_INVALID_FORMAT, \
    ERR_TYPE_MISMATCH, ERR_PRECISION_MISMATCH, ERR_UBOUND_LE_LBOUND, \
    ERR_MIN_DATE, ERR_MAX_DATE, ERR_MAX_UBOUND, ERR_INVALID_QUAL, \
    ERR_TZ_MISMATCH, ERR_INVALID_PERIOD_STRUCT = range(12)
ERR_UNKNOWN = 99
ERRMSG = {
    ERR_ARRAY_LEN: "Period argument expects an array with two or more elements.",
    ERR_INVALID_FORMAT: "Invalid or inconsistent date, time, or timestamp format encountered.",
    ERR_INVALID_DTTM: "Invalid date, time, or timestamp value encountered.",
    ERR_TYPE_MISMATCH: "The types of the period or instant arguments do not match.",
    ERR_PRECISION_MISMATCH: "The precision of the period or instant arguments do not match.",
    ERR_UBOUND_LE_LBOUND: "The upper bound is less than or equal to the lower bound.",
    ERR_MIN_DATE: "Cannot decrement a temporal type that is already at the minimum value.",
    ERR_MAX_DATE: "Cannot increment a temporal type that is already at the maximum value.",
    ERR_MAX_UBOUND: "Cannot compute interval for period with high value upper bound.",
    ERR_INVALID_QUAL: "Interval qualifier not compatible with the supplied period data type.",
    ERR_TZ_MISMATCH: "Timezone offset of period or instant arguments do not match.",
    ERR_INVALID_PERIOD_STRUCT: "Argument is not a valid Period struct. Use the Period() constructor to create period values.",
    ERR_UNKNOWN: "Unknown error."}
