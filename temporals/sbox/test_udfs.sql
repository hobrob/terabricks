

CREATE OR REPLACE TABLE test_udf_inputs AS
SELECT
  test_case_subject, test_case_number, concat(test_case_subject, '_', lpad(string(test_case_number), 3, '0')) AS test_case_id,
  test_sql, expected_result, test_notes
FROM (
    SELECT 'Header' as test_case_subject, 0 as test_case_number, null as test_sql, null as expected_result, null as test_notes UNION ALL
    SELECT 'Contains', 1, schema_name||'.Contains(array("2024-01-01", "2024-12-31"), "2024-07-15")', '= true', 'Date match in range, expect True' UNION ALL
    SELECT 'Contains', 2, schema_name||'.Contains(array("2024-01-01", "2024-06-01"), "2024-07-15")', '= false', 'Date outside range, expect False' UNION ALL
    SELECT 'Contains', 3, schema_name||'.Contains(array("02:00:00", "06:00:00"), "05:00:00")', '= true', 'Date match in range, expect True' UNION ALL
    SELECT 'Contains', 4, schema_name||'.Contains(array("02:00:00", "06:00:00"), "07:00:00")', '= false', 'Date outside range, expect False' UNION ALL
    SELECT 'Contains', 5, schema_name||'.Contains(array("2024-06-01 00:00:00", "2024-06-02 00:00:00"), "2024-06-01 00:00:00")', '= true', 'Timestamp inclusive lower bound, expect True' UNION ALL
    SELECT 'Contains', 6, schema_name||'.Contains(array("2024-06-01 00:00:00", "2024-06-02 00:00:00"), "2024-06-02 00:00:00")', '= false', 'Timestamp exclusive upper bound, expect False' UNION ALL
    SELECT 'Contains', 7, schema_name||'.Contains(array("2024-06-01 00:00:00", null), "2035-01-01 12:30:00")', '= true', 'Open-ended range, expect True' UNION ALL
    SELECT 'Contains', 8, schema_name||'.Contains(array("2024-02-32", "2024-03-01"), "2024-02-30")', '= "ValueError: Invalid date, time, or timestamp value encountered."', 'Invalid date, expect value error.' UNION ALL
    SELECT 'Contains', 9, schema_name||'.Contains(array("2024-02-20", "badformat"), "2024-02-30")', '= "ValueError: Invalid or inconsistent date, time, or timestamp format encountered."', 'Malformed date, expect value error.' UNION ALL
    SELECT 'Contains', 10, schema_name||'.Contains(array("2024-02-20", "02:00:00"), "2024-02-30")', '= "ValueError: Invalid or inconsistent date, time, or timestamp format encountered."', 'Malformed date, expect value error.' UNION ALL
    SELECT 'Contains', 11, schema_name||'.Contains(array("2024-06-01 00:00:00", "2024-06-02 00:00:00.000000"), "2024-06-01 00:00:00")', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched granularity, expect value error.' UNION ALL
    SELECT 'Contains', 12, schema_name||'.Contains(array("2024-06-01 00:00:00.000000", "2024-06-02 00:00:00.000000"), "2024-06-01 00:00:00")', '= "ValueError: The precision of the period or instant arguments do not match."', 'Instant precision mismatch.' UNION ALL
    SELECT 'Contains', 13, schema_name||'.Contains(array("2024-06-01 00:00:00.00", "2024-06-02 00:00:00.00"), "2024-06-01")', '= "ValueError: The types of the period or instant arguments do not match."', 'Instant precision mismatch.' UNION ALL
    SELECT 'Contains', 14, schema_name||'.Contains(array("2024-06-01"), "2024-06-01")', '= "ValueError: Period argument expects an array with two or more elements."', 'Period with only one element, expect value error.' UNION ALL
    SELECT 'Contains', 15, schema_name||'.Contains(array(), "2024-06-01")', '= "ValueError: Period argument expects an array with two or more elements."', 'Empty array, expect value error.' UNION ALL
    SELECT 'Contains', 16, schema_name||'.Contains(null, "2024-06-01")', '= "ValueError: Period argument expects an array with two or more elements."', 'NULL period, expect value error.' UNION ALL
    SELECT 'Contains', 17, schema_name||'.Contains(array("2024-06-01", "2024-06-30"), 12345)', '= "ValueError: Invalid or inconsistent date, time, or timestamp format encountered."', 'Non-string instant input, expect value error' UNION ALL
    SELECT 'Contains', 18, schema_name||'.Contains(array("2024-06-01 00:00:00", "xxxxxxxxxxxxxxxxxxx"), "2024-06-01 00:00:00")', '= "ValueError: Invalid or inconsistent date, time, or timestamp format encountered."', 'String of gibberish, expect value error' UNION ALL
    SELECT 'Contains', 19, schema_name||'.Contains(array("2024-06-01 00:00:00", "2024-06-30 00:00:00"), "")', '= "ValueError: Invalid or inconsistent date, time, or timestamp format encountered."', 'Empty string instant, expect value error' UNION ALL
    SELECT 'Contains', 20, schema_name||'.Contains(array("2024-06-01", "2024-07-01", "extra"), "2024-06-15")', '= true', 'Extra metadata, no error' UNION ALL
    SELECT 'Begin', 1, schema_name||'.Begin(array("2024-01-01", "2024-12-31"))', '= "2024-01-01"', 'Standard date range, expect first date returned' UNION ALL
    SELECT 'Begin', 2, schema_name||'.Begin(array("13:50:00.123", "14:10:00.456"))', '= "13:50:00.123000"', 'Partial-precision time range, expect first value with trailing zero-padded precision' UNION ALL
    SELECT 'Begin', 3, schema_name||'.Begin(array("2024-06-01 00:00:00.123456", "2024-06-30 00:00:00.123456"))', '= "2024-06-01 00:00:00.123456"', 'Full-precision timestamp range, expect precise first value' UNION ALL
    SELECT 'Begin', 4, schema_name||'.Begin(null)', 'is null', 'Null input, expect graceful fallback' UNION ALL
    SELECT 'Begin', 5, schema_name||'.Begin(array("2024-01-01"))', '= "ValueError: Period argument expects an array with two or more elements."', 'Invalid input: single-element array, expect error' UNION ALL
    SELECT 'Begin', 6, schema_name||'.Begin(array("badformat", "2024-06-30"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed start value, expect validation failure' UNION ALL
    SELECT 'Begin', 7, schema_name||'.Begin(array("2024-01-01", "2024-12-33"))', '= "ValueError: Invalid date, time, or timestamp value encountered."', 'Impossible date, expect validation failure' UNION ALL
    SELECT 'Begin', 8, schema_name||'.Begin(array("2024-01-01", "2023-12-31"))', '= "ValueError: The upper bound is less than or equal to the lower bound."', 'Invalid upper bound, expect validation failure' UNION ALL
    SELECT 'End', 1, schema_name||'.End(array("2024-01-01", "2024-12-31"))', '= "2024-12-31"', 'Standard date range, expect second date returned' UNION ALL
    SELECT 'End', 2, schema_name||'.End(array("13:50:00.123", "14:10:00.456"))', '= "14:10:00.456000"', 'Partial-precision time range, expect second value with trailing zero-padded precision' UNION ALL
    SELECT 'End', 3, schema_name||'.End(array("2024-06-01 00:00:00.123456", "2024-06-30 00:00:00.123456"))', '= "2024-06-30 00:00:00.123456"', 'Full-precision timestamp range, expect precise second value' UNION ALL
    SELECT 'End', 4, schema_name||'.End(array("2024-06-01 00:00:00.123456", null))', '= "9999-12-31 23:59:59.999999"', 'Null upper bound, expect highest possible datetime' UNION ALL
    SELECT 'End', 5, schema_name||'.End(null)', 'is null', 'Null input, expect graceful fallback' UNION ALL
    SELECT 'End', 6, schema_name||'.End(array("2024-01-01"))', '= "ValueError: Period argument expects an array with two or more elements."', 'Invalid input: single-element array, expect error' UNION ALL
    SELECT 'End', 7, schema_name||'.End(array("badformat", "2024-06-30"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed start value, expect validation failure' UNION ALL
    SELECT 'End', 8, schema_name||'.End(array("2024-01-01", "2024-12-33"))', '= "ValueError: Invalid date, time, or timestamp value encountered."', 'Impossible date, expect validation failure' UNION ALL
    SELECT 'End', 9, schema_name||'.End(array("2024-01-01", "2023-12-31"))', '= "ValueError: The upper bound is less than or equal to the lower bound."', 'Invalid upper bound, expect validation failure' UNION ALL
    SELECT 'Overlaps', 1, schema_name||'.Overlaps(array("2024-01-01", "2024-06-01"), array("2024-05-01", "2024-07-01"))', '= true', 'Partial overlap at end of first range' UNION ALL
    SELECT 'Overlaps', 2, schema_name||'.Overlaps(array("2024-05-01", "2024-07-01"), array("2024-01-01", "2024-06-01"))', '= true', 'Partial overlap at beginning of first range' UNION ALL
    SELECT 'Overlaps', 3, schema_name||'.Overlaps(array("2024-01-01", "2024-12-31"), array("2024-03-01", "2024-05-01"))', '= true', 'Second period wholly consumed by first' UNION ALL
    SELECT 'Overlaps', 4, schema_name||'.Overlaps(array("2024-03-01", "2024-05-01"), array("2024-01-01", "2024-12-31"))', '= true', 'First period wholly consumed by second' UNION ALL
    SELECT 'Overlaps', 5, schema_name||'.Overlaps(array("2024-01-01", "2024-03-01"), array("2024-03-01", "2024-05-01"))', '= false', 'Touching but not overlapping (boundary only)' UNION ALL
    SELECT 'Overlaps', 6, schema_name||'.Overlaps(array("2024-01-01", "2024-02-01"), array("2024-03-01", "2024-04-01"))', '= false', 'No overlap at all' UNION ALL
    SELECT 'Overlaps', 7, schema_name||'.Overlaps(array("2024-01-01", "2024-12-31"), null)', 'is null', 'Second period is null, expect graceful fallback' UNION ALL
    SELECT 'Overlaps', 8, schema_name||'.Overlaps(null, array("2024-01-01", "2024-12-31"))', 'is null', 'First period is null, expect graceful fallback' UNION ALL
    SELECT 'Overlaps', 9, schema_name||'.Overlaps(array("2024-01-01"), array("2024-01-01", "2024-12-31"))', '= "ValueError: Period argument expects an array with two or more elements."', 'First period too short' UNION ALL
    SELECT 'Overlaps', 10, schema_name||'.Overlaps(array("badformat", "2024-12-31"), array("2024-01-01", "2024-12-31"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed start value in first period' UNION ALL
    SELECT 'Overlaps', 11, schema_name||'.Overlaps(array("2024-01-01", "2023-12-31"), array("2024-01-01", "2024-12-31"))', '= "ValueError: The upper bound is less than or equal to the lower bound."', 'Invalid ordering in first period' UNION ALL
    SELECT 'Overlaps', 12, schema_name||'.Overlaps(array("2024-01-01", "2024-12-31"), array("2024-12-31"))', '= "ValueError: Period argument expects an array with two or more elements."', 'Second period too short' UNION ALL
    SELECT 'Overlaps', 13, schema_name||'.Overlaps(array("2024-01-01", "2024-12-31"), array("badformat", "2024-12-31"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed start value in second period' UNION ALL
    SELECT 'Overlaps', 14, schema_name||'.Overlaps(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2023-12-31"))', '= "ValueError: The upper bound is less than or equal to the lower bound."', 'Invalid ordering in second period' UNION ALL
    SELECT 'Last', 1, schema_name||'.Last(array("2024-01-01", "2024-12-31"))', '= "2024-12-30"', 'Standard date range, expect end date minus 1 day' UNION ALL
    SELECT 'Last', 2, schema_name||'.Last(array("13:50:00.123", "14:10:00.456"))', '= "14:10:00.455000"', 'Partial-precision time range, expect upper bound minus 1/1000 second' UNION ALL
    SELECT 'Last', 3, schema_name||'.Last(array("2024-06-01 00:00:00.123456", "2024-06-30 00:00:00.654321"))', '= "2024-06-30 00:00:00.654320"', 'Full-precision timestamp range, expect upper bound minus 1 microsecond.' UNION ALL
    SELECT 'Last', 4, schema_name||'.Last(null)', 'is null', 'Null input, expect graceful fallback' UNION ALL
    SELECT 'Last', 5, schema_name||'.Last(array("2024-01-01"))', '= "ValueError: Period argument expects an array with two or more elements."', 'Invalid input: single-element array, expect error' UNION ALL
    SELECT 'Last', 6, schema_name||'.Last(array("badformat", "2024-12-31"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed lower bound, expect error' UNION ALL
    SELECT 'Last', 7, schema_name||'.Last(array("2024-01-01", "badformat"))', '= "ValueError: Invalid date, time, or timestamp format encountered."', 'Malformed upper bound, expect error' UNION ALL
    SELECT 'Last', 8, schema_name||'.Last(array("2024-01-01", "2023-12-31"))', '= "ValueError: The upper bound is less than or equal to the lower bound."', 'Upper bound comes before lower bound, expect validation failure' UNION ALL
    SELECT 'Next', 1, schema_name||'.Next("2024-01-01")', '= "2024-01-02"', 'Standard date, expect input date plus 1 day' UNION ALL
    SELECT 'Next', 2, schema_name||'.Next("12:59:00")', '= "12:59:01"', 'Standard time, expect input time plus 1 second' UNION ALL
    SELECT 'Next', 3, schema_name||'.Next("2024-01-01 12:59:00")', '= "2024-01-01 12:59:01"', 'Standard timestamp, expect input time plus 1 second' UNION ALL
    SELECT 'Next', 4, schema_name||'.Next("2024-01-01 12:59:00.123")', '= "2024-01-01 12:59:00.124000"', 'Standard timestamp with millisecond precision, expect input time plus 1 millisecond' UNION ALL
    SELECT 'Next', 5, schema_name||'.Next("2024-01-01 12:59:00.123456")', '= "2024-01-01 12:59:00.123457"', 'Standard timestamp with microsecond precision, expect input time plus 1 microsecond' UNION ALL
    SELECT 'Next', 6, schema_name||'.Next("9999-12-31 23:59:59.990")', '= "9999-12-31 23:59:59.991000"', 'Standard timestamp close to max value, expect input time plus 1 millisecond' UNION ALL
    SELECT 'Next', 7, schema_name||'.Next("9999-12-31")', '= "ValueError: Cannot increment a temporal type that is already at the maximum value."', 'Standard date, max value error' UNION ALL
    SELECT 'Next', 8, schema_name||'.Next("23:59:59")', '= "ValueError: Cannot increment a temporal type that is already at the maximum value."', 'Standard time, max value error' UNION ALL
    SELECT 'Next', 9, schema_name||'.Next("9999-12-31 23:59:59")', '= "ValueError: Cannot increment a temporal type that is already at the maximum value."', 'Standard timestamp, max value error' UNION ALL
    SELECT 'Prior', 1, schema_name||'.Prior("2024-01-01")', '= "2024-01-02"', 'Standard date, expect input date minus 1 day' UNION ALL
    SELECT 'Prior', 2, schema_name||'.Prior("12:59:00")', '= "12:58:59"', 'Standard time, expect input time minus 1 second' UNION ALL
    SELECT 'Prior', 3, schema_name||'.Prior("2024-01-01 12:59:00")', '= "2024-01-01 12:58:59"', 'Standard timestamp, expect input time minus 1 second' UNION ALL
    SELECT 'Prior', 4, schema_name||'.Prior("2024-01-01 12:59:00.123")', '= "2024-01-01 12:59:00.122000"', 'Standard timestamp with millisecond precision, expect input time minus 1 millisecond' UNION ALL
    SELECT 'Prior', 5, schema_name||'.Prior("2024-01-01 12:59:00.123456")', '= "2024-01-01 12:59:00.123455"', 'Standard timestamp with microsecond precision, expect input time minus 1 microsecond' UNION ALL
    SELECT 'Prior', 6, schema_name||'.Prior("0001-01-01 00:00:00.002")', '= "0001-01-01 00:00:00.001000"', 'Standard timestamp close to max value, expect input time plus 1 millisecond' UNION ALL
    SELECT 'Prior', 7, schema_name||'.Prior("0001-01-01")', '= "ValueError: Cannot decrement a temporal type that is already at the minimum value."', 'Standard date, max value error' UNION ALL
    SELECT 'Prior', 8, schema_name||'.Prior("00:00:00")', '= "ValueError: Cannot decrement a temporal type that is already at the minimum value."', 'Standard time, max value error' UNION ALL
    SELECT 'Prior', 9, schema_name||'.Prior("0001-01-01 00:00:00")', '= "ValueError: Cannot decrement a temporal type that is already at the minimum value."', 'Standard timestamp, max value error' UNION ALL
    SELECT 'MeetsInstant', 1, schema_name||'.MeetsInstant(array("2024-01-01", "2024-06-01"), "2023-12-31")', '= true', 'Instant meets lower bound of period' UNION ALL
    SELECT 'MeetsInstant', 2, schema_name||'.MeetsInstant(array("2024-05-01", "2024-07-01"), "2024-07-01")', '= true', 'Instant meets upper bound of period' UNION ALL
    SELECT 'MeetsInstant', 3, schema_name||'.MeetsInstant(array("08:00:00", "09:00:00"), "07:59:59")', '= true', 'Instant meets lower bound of period' UNION ALL
    SELECT 'MeetsInstant', 4, schema_name||'.MeetsInstant(array("08:00:00.00", "09:00:00.00"), "09:00:00.00")', '= true', 'Instant meets upper bound of period' UNION ALL
    SELECT 'MeetsInstant', 5, schema_name||'.MeetsInstant(array("2024-03-01 04:00:00.123456", "2024-03-01 05:00:00.654321"), "2024-03-01 04:00:00.123455")', '= true', 'Instant meets lower bound of period' UNION ALL
    SELECT 'MeetsInstant', 6, schema_name||'.MeetsInstant(array("2024-01-01", "2024-06-01"), "2023-12-30")', '= false', 'Instant does not meet lower bound of period' UNION ALL
    SELECT 'MeetsInstant', 7, schema_name||'.MeetsInstant(array("08:00:00.00", "09:00:00.00"), "09:00:00.10")', '= false', 'Instant does not meet upper bound of period' UNION ALL
    SELECT 'MeetsInstant', 8, schema_name||'.MeetsInstant(array("2024-03-01 04:00:00.123456", "2024-03-01 05:00:00.654321"), "2024-03-01 04:30:00.000000")', '= false', 'Instant falls within period' UNION ALL
    SELECT 'MeetsInstant', 9, schema_name||'.MeetsInstant(null, "2024-12-31")', 'is null', 'Period is null, expect graceful fallback' UNION ALL
    SELECT 'MeetsInstant', 10, schema_name||'.MeetsInstant(array("2024-01-01", "2024-12-31"), null)', 'is null', 'Instant is null, expect graceful fallback' UNION ALL
    SELECT 'MeetsInstant', 11, schema_name||'.MeetsInstant(array("2024-01-01", "2024-06-01"), "2023-12-31 21:00:00")', '= "ValueError: The types of the period or instant arguments do not match."', 'Inconsistent temporal types, expect type mismatch error' UNION ALL
    SELECT 'MeetsInstant', 12, schema_name||'.MeetsInstant(array("08:00:00.00", "09:00:00.00"), "23:59:59.99")', '= "ValueError: Cannot increment a temporal type that is already at the maximum value."', 'Instant does not meet upper bound of period' UNION ALL
    SELECT 'MeetsPeriod', 1, schema_name||'.MeetsPeriod(array("2024-01-01", "2024-06-01"), array("2023-06-01", "2024-01-01"))', '= true', 'Second period meets lower bound of first period' UNION ALL
    SELECT 'MeetsPeriod', 2, schema_name||'.MeetsPeriod(array("2024-05-01", "2024-07-01"), array("2024-07-01", "2024-09-01"))', '= true', 'First period meets lower bound of second period' UNION ALL
    SELECT 'MeetsPeriod', 3, schema_name||'.MeetsPeriod(array("08:00:00", "09:00:00"), array("07:00:00", "08:00:00"))', '= true', 'Instant meets lower bound of period' UNION ALL
    SELECT 'MeetsPeriod', 4, schema_name||'.MeetsPeriod(array("08:00:00.00", "09:00:00.00"), array("09:00:00.00", "10:00:00.00"))', '= true', 'Instant meets upper bound of period' UNION ALL
    SELECT 'MeetsPeriod', 5, schema_name||'.MeetsPeriod(array("2024-03-01 04:00:00.123456", "2024-03-01 05:00:00.654321"), array("2024-03-01 03:00:00.000000", "2024-03-01 04:00:00.123456"))', '= true', 'Instant meets lower bound of period' UNION ALL
    SELECT 'MeetsPeriod', 6, schema_name||'.MeetsPeriod(array("2024-01-01", "2024-06-01"), array("2023-12-01", "2023-12-30"))', '= false', 'Instant does not meet lower bound of period' UNION ALL
    SELECT 'MeetsPeriod', 7, schema_name||'.MeetsPeriod(array("08:00:00.00", "09:00:00.00"), array("09:00:00.10", "10:00:00.00"))', '= false', 'Instant does not meet upper bound of period' UNION ALL
    SELECT 'MeetsPeriod', 8, schema_name||'.MeetsPeriod(array("2024-03-01 04:00:00.123456", "2024-03-01 05:00:00.654321"), array("2024-03-01 04:30:00.000000", "2024-03-01 04:31:00.000000"))', '= false', 'Instant falls within period' UNION ALL
    SELECT 'MeetsPeriod', 9, schema_name||'.MeetsPeriod(null, array("2024-12-01", "2024-12-31"))', 'is null', 'Period is null, expect graceful fallback' UNION ALL
    SELECT 'MeetsPeriod', 10, schema_name||'.MeetsPeriod(array("2024-01-01", "2024-12-31"), null)', 'is null', 'Instant is null, expect graceful fallback' UNION ALL
    SELECT 'MeetsPeriod', 11, schema_name||'.MeetsPeriod(array("2024-01-01", "2024-06-01"), array("2023-12-01 21:00:00", "2023-12-31 21:00:00"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Inconsistent temporal types, expect type mismatch error' UNION ALL
    SELECT 'Interval', 1, schema_name||'.IntervalY(array("2024-01-01", "2024-12-31"))', '= INTERVAL "0" YEAR', 'Period one day shorter than a full year' UNION ALL
    SELECT 'Interval', 2, schema_name||'.IntervalY(array("2021-01-01 02:00:00", "2025-01-01 14:00:00"))', '= INTERVAL "4" YEAR', 'Period in excess of four years' UNION ALL
    SELECT 'Interval', 3, schema_name||'.IntervalY(null)', 'is null', 'Period is null, expect graceful fallback' UNION ALL
    SELECT 'Interval', 4, schema_name||'.IntervalY(array("02:00:00", "04:00:00"))', '= "ValueError: Interval qualifier not compatible with the supplied period data type."', 'Time period supplied with incorrect qualifier, expect invalid qualifier error' UNION ALL
    SELECT 'Interval', 5, schema_name||'.IntervalY(array("2021-01-01 02:00:00", null))', '= "ValueError: Cannot compute interval for period with high value upper bound."', 'Period is open-ended, expect invalid upper bound error.' UNION ALL
    SELECT 'Interval', 6, schema_name||'.IntervalY2M(array("2021-01-01 02:00:00", "2025-06-01 14:00:00"))', '= INTERVAL "4-5" YEAR TO MONTH', 'Period of 4 years and 5 months' UNION ALL
    SELECT 'Interval', 7, schema_name||'.IntervalMO(array("2025-01-01 02:00:00", "2025-07-01 14:00:00"))', '= INTERVAL "6" MONTH', 'Period of 6 months' UNION ALL
    SELECT 'Interval', 8, schema_name||'.IntervalD(array("2024-01-01 01:00:00", "2024-01-11 09:00:00"))', '= INTERVAL "10" DAY', 'Period of 10 days' UNION ALL
    SELECT 'Interval', 9, schema_name||'.IntervalD2H(array("2024-01-01 02:00:00", "2024-01-03 08:00:00"))', '= INTERVAL "2 06" DAY TO HOUR', 'Period of 2 days and 6 hours' UNION ALL
    SELECT 'Interval', 10, schema_name||'.IntervalD2H(array("2024-01-01", "2024-01-03"))', '= "ValueError: Interval qualifier not compatible with the supplied period data type."', 'Date period supplied with incorrect qualifier, expect invalid qualifier error' UNION ALL
    SELECT 'Interval', 11, schema_name||'.IntervalD2M(array("2024-01-01 02:10:00", "2024-01-03 08:43:00"))', '= INTERVAL "2 06:33" DAY TO MINUTE', 'Period of 2 days, 6 hours, and 33 minutes' UNION ALL
    SELECT 'Interval', 12, schema_name||'.IntervalD2S(array("2024-01-01 02:10:15", "2024-01-03 08:43:35"))', '= INTERVAL "2 06:33:20" DAY TO SECOND', 'Period of 2 days, 6 hours, 33 minutes, and 20 seconds' UNION ALL
    SELECT 'Interval', 13, schema_name||'.IntervalD2S(array("2024-01-01 02:10:15.25", "2024-01-03 08:43:35.78"))', '= INTERVAL "2 06:33:20.53" DAY TO SECOND', 'Period of 2 days, 6 hours, 33 minutes, and 20 seconds with 1/100 second precision' UNION ALL
    SELECT 'Interval', 14, schema_name||'.IntervalH(array("2024-01-01 01:00:00", "2024-01-11 09:00:00"))', '= INTERVAL "248" HOUR', 'Period of 248 hours' UNION ALL
    SELECT 'Interval', 15, schema_name||'.IntervalH2M(array("2024-01-01 01:10:00", "2024-01-11 09:43:00"))', '= INTERVAL "248:33" HOUR TO MINUTE', 'Period of 248 hours and 33 minutes' UNION ALL
    SELECT 'Interval', 16, schema_name||'.IntervalH2S(array("2024-01-01 01:10:15", "2024-01-11 09:43:35"))', '= INTERVAL "248:33:20" HOUR TO SECOND', 'Period of 248 hours, 33 minutes, and 20 seconds' UNION ALL
    SELECT 'Interval', 17, schema_name||'.IntervalM(array("2024-01-01 01:00:00", "2024-01-11 09:00:00"))', '= INTERVAL "14880" MINUTE', 'Period of 14880 minutes' UNION ALL
    SELECT 'Interval', 18, schema_name||'.IntervalM2S(array("2024-01-01 01:00:15", "2024-01-11 09:00:35"))', '= INTERVAL "14880:20" MINUTE TO SECOND', 'Period of 14880 minutes and 20 seconds' UNION ALL
    SELECT 'Interval', 19, schema_name||'.IntervalS(array("2024-01-01 01:00:15", "2024-01-11 09:00:35"))', '= INTERVAL "892820" SECOND', 'Period of 892820 seconds' UNION ALL
    SELECT 'IsUntilChanged', 1, schema_name||'.IsUntilChanged(array("2024-01-01", "2024-12-31"))', '= false', 'End-dated date-typed period' UNION ALL
    SELECT 'IsUntilChanged', 2, schema_name||'.IsUntilChanged(array("2024-01-01", "9999-12-31"))', '= true', 'Open-dated date-typed period' UNION ALL
    SELECT 'IsUntilChanged', 3, schema_name||'.IsUntilChanged(array("12:00:00", "13:00:00"))', '= false', 'End-dated time-typed period' UNION ALL
    SELECT 'IsUntilChanged', 4, schema_name||'.IsUntilChanged(array("12:00:00", "23:59:59"))', '= true', 'Open-ended time-typed period' UNION ALL
    SELECT 'IsUntilChanged', 5, schema_name||'.IsUntilChanged(array("12:00:00", "23:59:59.99"))', '= true', 'Open-ended time-typed period with 1/100 second precision' UNION ALL
    SELECT 'IsUntilChanged', 6, schema_name||'.IsUntilChanged(array("2024-01-01 00:00:00", "2024-12-31 23:59:59"))', '= false', 'End-dated timestamp-typed period' UNION ALL
    SELECT 'IsUntilChanged', 7, schema_name||'.IsUntilChanged(array("2024-01-01 00:00:00", "9999-12-31 23:59:59"))', '= true', 'Open-ended timestamp-typed period' UNION ALL
    SELECT 'IsUntilChanged', 8, schema_name||'.IsUntilChanged(array("2024-01-01 00:00:00", "9999-12-31 23:59:59.900"))', '= false', 'End-dated timestamp-typed period with millisecond precision and trailing zeros' UNION ALL
    SELECT 'Equals', 1, schema_name||'.Equals(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2025-12-31"))', '= false', 'Date-typed periods with different upper bound' UNION ALL
    SELECT 'Equals', 2, schema_name||'.Equals(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2024-12-31"))', '= true', 'Date-typed periods with exactly the same range' UNION ALL
    SELECT 'Equals', 3, schema_name||'.Equals(array("02:00:00", "04:00:00"), array("01:00:00", "04:00:00"))', '= false', 'Time-typed periods with different lower bound' UNION ALL
    SELECT 'Equals', 4, schema_name||'.Equals(array("02:00:00", "04:00:00"), array("02:00:00", "04:00:00"))', '= true', 'Time-typed periods with exactly the same range' UNION ALL
    SELECT 'Equals', 5, schema_name||'.Equals(array("2024-01-01 05:00:00", "2024-12-31 06:00:00"), array("2024-01-01 04:00:00", "2025-12-31 05:00:00"))', '= false', 'Timestamp-typed periods with different upper and lower bounds' UNION ALL
    SELECT 'Equals', 6, schema_name||'.Equals(array("2024-01-01 05:00:00", "2025-12-31 06:00:00"), array("2024-01-01 05:00:00", "2025-12-31 06:00:00"))', '= true', 'Timestamp-typed periods with exactly the same range' UNION ALL
    SELECT 'Equals', 7, schema_name||'.Equals(array("2024-01-01 05:00:00", null), array("2024-01-01 05:00:00", null))', '= true', 'Open-ended periods are treated as equal' UNION ALL
    SELECT 'Equals', 8, schema_name||'.Equals(array("2024-01-01", "2024-12-31"), array("05:00:00", "06:00:00"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Conflicting period types, expect a type mismatch error' UNION ALL
    SELECT 'Equals', 9, schema_name||'.Equals(array("2024-01-01 05:00:00.20", "2024-12-31 06:00:00.50"), array("2024-01-01 05:00:00.200", "2025-12-31 06:00:00.500"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Conflicting precision, expect a precision mismatch error' UNION ALL
    SELECT 'Precedes', 1, schema_name||'.Precedes(array("2024-01-01", "2024-03-31"), array("2024-04-01", "2024-06-30"))', '= true', 'Date-typed periods where first ends before second starts' UNION ALL
    SELECT 'Precedes', 2, schema_name||'.Precedes(array("05:00:00", "06:00:00"), array("06:00:00", "08:00:00"))', '= true', 'Time-typed periods end-to-start boundary match' UNION ALL
    SELECT 'Precedes', 3, schema_name||'.Precedes(array("2024-01-01 05:00:00", "2024-12-31 06:00:00"), array("2024-12-31 06:00:01", "2025-01-01 08:00:00"))', '= true', 'Timestamp periods where first ends one second before second begins' UNION ALL
    SELECT 'Precedes', 4, schema_name||'.Precedes(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2024-12-31"))', '= false', 'Periods overlap fully' UNION ALL
    SELECT 'Precedes', 5, schema_name||'.Precedes(array("05:00:00", "07:00:00"), array("06:59:59", "08:00:00"))', '= false', 'Time periods slightly overlap' UNION ALL
    SELECT 'Precedes', 6, schema_name||'.Precedes(array("2024-01-01", "2024-12-31"), array("05:00:00", "06:00:00"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'Precedes', 7, schema_name||'.Precedes(array("05:00:00.200", "06:00:00.800"), array("06:00:00.2", "08:00:00.8"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'ImmediatelyPrecedes', 1, schema_name||'.ImmediatelyPrecedes(array("2024-01-01", "2024-04-01"), array("2024-04-01", "2024-06-30"))', '= true', 'Date periods touch exactly' UNION ALL
    SELECT 'ImmediatelyPrecedes', 2, schema_name||'.ImmediatelyPrecedes(array("06:00:00", "07:59:59"), array("07:59:59", "09:00:00"))', '= true', 'Time periods touching at precision boundary' UNION ALL
    SELECT 'ImmediatelyPrecedes', 3, schema_name||'.ImmediatelyPrecedes(array("2024-01-01 04:00:00", "2024-01-01 06:00:00"), array("2024-01-01 06:00:00", "2024-01-01 08:00:00"))', '= true', 'Timestamp second-by-second match' UNION ALL
    SELECT 'ImmediatelyPrecedes', 4, schema_name||'.ImmediatelyPrecedes(array("2024-01-01", "2024-11-30"), array("2024-01-01", "2024-12-31"))', '= false', 'Start does not equal end of second' UNION ALL
    SELECT 'ImmediatelyPrecedes', 5, schema_name||'.ImmediatelyPrecedes(array("05:00:00", "06:00:00"), array("2024-01-01", "2024-12-31"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'ImmediatelyPrecedes', 6, schema_name||'.ImmediatelyPrecedes(array("2024-01-01 04:00:00.0000", "2024-01-01 06:00:00.0000"), array("2024-01-01 06:00:00.00", "2024-01-01 08:00:00.00"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'Succeeds', 1, schema_name||'.Succeeds(array("2024-07-01", "2024-09-30"), array("2024-04-01", "2024-06-30"))', '= true', 'Date-typed period1 starts after period2 ends' UNION ALL
    SELECT 'Succeeds', 2, schema_name||'.Succeeds(array("08:00:00", "10:00:00"), array("06:00:00", "07:59:59"))', '= true', 'Time periods non-overlapping, sequential' UNION ALL
    SELECT 'Succeeds', 3, schema_name||'.Succeeds(array("2025-01-01 00:00:01", "2025-03-01 00:00:00"), array("2024-12-31 23:59:59", "2025-01-01 00:00:00"))', '= true', 'Timestamp periods with 1-second separation' UNION ALL
    SELECT 'Succeeds', 4, schema_name||'.Succeeds(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2024-12-31"))', '= false', 'Identical periods should not succeed each other' UNION ALL
    SELECT 'Succeeds', 5, schema_name||'.Succeeds(array("2025-01-01 00:00:00", "2025-03-01 01:00:01"), array("2025-03-01 01:00:00", "2025-05-01 00:00:00"))', '= false', 'Timestamp periods with 1-second separation' UNION ALL
    SELECT 'Succeeds', 6, schema_name||'.Succeeds(array("2024-01-01", "2024-12-31"), array("06:00:00", "07:00:00"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'Succeeds', 7, schema_name||'.Succeeds(array("2025-01-01 00:00:01.10", "2025-03-01 00:00:00.00"), array("2024-12-31 23:59:59.1", "2025-01-01 00:00:00.0"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'ImmediatelySucceeds', 1, schema_name||'.ImmediatelySucceeds(array("2024-04-01", "2024-06-30"), array("2024-01-01", "2024-04-01"))', '= true', 'Date periods touch exactly' UNION ALL
    SELECT 'ImmediatelySucceeds', 2, schema_name||'.ImmediatelySucceeds(array("07:59:59", "09:00:00"), array("06:00:00", "07:59:59"))', '= true', 'Time periods touching at precision boundary' UNION ALL
    SELECT 'ImmediatelySucceeds', 3, schema_name||'.ImmediatelySucceeds(array("2024-01-01 06:00:00", "2024-01-01 08:00:00"), array("2024-01-01 04:00:00", "2024-01-01 06:00:00"))', '= true', 'Timestamp second-by-second match' UNION ALL
    SELECT 'ImmediatelySucceeds', 4, schema_name||'.ImmediatelySucceeds(array("2024-01-01", "2024-12-31"), array("2024-01-01", "2024-11-30"))', '= false', 'Start does not equal end of second' UNION ALL
    SELECT 'ImmediatelySucceeds', 5, schema_name||'.ImmediatelySucceeds(array("2024-01-01", "2024-12-31"), array("05:00:00", "06:00:00"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'ImmediatelySucceeds', 6, schema_name||'.ImmediatelySucceeds(array("2024-01-01 06:00:00.00", "2024-01-01 08:00:00.00"), array("2024-01-01 04:00:00.0000", "2024-01-01 06:00:00.0000"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'LDiff', 1, schema_name||'.LDiff(array("2024-01-01", "2024-06-01"), array("2024-05-01", "2024-12-31"))', '= array("2024-01-01", "2024-05-01")', 'Date overlap at tail of p1' UNION ALL
    SELECT 'LDiff', 2, schema_name||'.LDiff(array("01:01:00", "03:01:00"), array("02:15:00", "04:01:00"))', '= array("01:01:00", "02:15:00")', 'Date overlap at tail of p1' UNION ALL
    SELECT 'LDiff', 3, schema_name||'.LDiff(array("2024-01-01 01:01:00.20", "2024-06-01 03:01:00.50"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= array("2024-01-01 01:01:00.20", "2024-03-01 02:15:00.45")', 'Timestamp overlap at tail of p1' UNION ALL
    SELECT 'LDiff', 4, schema_name||'.LDiff(array("2024-03-01", "2024-04-01"), array("2024-01-01", "2024-02-01"))', 'is null', 'p1 entirely after p2' UNION ALL
    SELECT 'LDiff', 5, schema_name||'.LDiff(array("2024-01-01", "2024-03-01"), array("2024-01-01", "2024-03-01"))', 'is null', 'Exact match' UNION ALL
    SELECT 'LDiff', 6, schema_name||'.LDiff(array("01:01:00", "03:01:00"), array("2024-05-01", "2024-12-31"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'LDiff', 7, schema_name||'.LDiff(array("2024-01-01 01:01:00.2000", "2024-06-01 03:01:00.5050"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'RDiff', 1, schema_name||'.RDiff(array("2024-01-01", "2024-06-01"), array("2024-05-01", "2024-12-31"))', '= array("2024-06-01", "2024-12-31")', 'Date overlap at head of p12' UNION ALL
    SELECT 'RDiff', 2, schema_name||'.RDiff(array("01:01:00", "03:01:00"), array("02:15:00", "04:01:00"))', '= array("03:01:00", "04:01:00")', 'Date overlap at head of p1' UNION ALL
    SELECT 'RDiff', 3, schema_name||'.RDiff(array("2024-01-01 01:01:00.20", "2024-06-01 03:01:00.50"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= array("2024-06-01 03:01:00.50", "2024-08-01 04:01:00.30")', 'Timestamp overlap at head of p1' UNION ALL
    SELECT 'RDiff', 4, schema_name||'.RDiff(array("2024-03-01", "2024-04-01"), array("2024-01-01", "2024-02-01"))', 'is null', 'p1 entirely after p2' UNION ALL
    SELECT 'RDiff', 5, schema_name||'.RDiff(array("2024-01-01", "2024-03-01"), array("2024-01-01", "2024-03-01"))', 'is null', 'Exact match' UNION ALL
    SELECT 'RDiff', 6, schema_name||'.RDiff(array("01:01:00", "03:01:00"), array("2024-05-01", "2024-12-31"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'RDiff', 7, schema_name||'.RDiff(array("2024-01-01 01:01:00.2000", "2024-06-01 03:01:00.5050"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError' UNION ALL
    SELECT 'P_Intersect', 1, schema_name||'.P_Intersect(array("2024-01-01", "2024-06-01"), array("2024-05-01", "2024-12-31"))', '= array("2024-05-01", "2024-06-01")', 'Date overlap at head of p12' UNION ALL
    SELECT 'P_Intersect', 2, schema_name||'.P_Intersect(array("01:01:00", "03:01:00"), array("02:15:00", "04:01:00"))', '= array("02:15:00", "03:01:00")', 'Date overlap at head of p1' UNION ALL
    SELECT 'P_Intersect', 3, schema_name||'.P_Intersect(array("2024-01-01 01:01:00.20", "2024-06-01 03:01:00.50"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= array("2024-03-01 02:15:00.45", "2024-06-01 03:01:00.50")', 'Timestamp overlap at head of p1' UNION ALL
    SELECT 'P_Intersect', 4, schema_name||'.P_Intersect(array("2024-03-01", "2024-04-01"), array("2024-01-01", "2024-02-01"))', 'is null', 'p1 entirely after p2' UNION ALL
    SELECT 'P_Intersect', 5, schema_name||'.P_Intersect(array("2024-01-01", "2024-03-01"), array("2024-01-01", "2024-03-01"))', '= array("2024-01-01", "2024-03-01")', 'Exact match' UNION ALL
    SELECT 'P_Intersect', 6, schema_name||'.P_Intersect(array("01:01:00", "03:01:00"), array("2024-05-01", "2024-12-31"))', '= "ValueError: The types of the period or instant arguments do not match."', 'Mismatched types, expect ValueError' UNION ALL
    SELECT 'P_Intersect', 7, schema_name||'.P_Intersect(array("2024-01-01 01:01:00.2000", "2024-06-01 03:01:00.5050"), array("2024-03-01 02:15:00.45", "2024-08-01 04:01:00.30"))', '= "ValueError: The precision of the period or instant arguments do not match."', 'Mismatched precision, expect ValueError'
) t cross join (select 'funlib' as schema_name);


# Test routine iterates through each input row and executes the function call in an isolated SELECT statement
# Successful completions are logged, errors are caught and also logged
BEGIN

    DECLARE SQLTx STRING DEFAULT '';

    CREATE OR REPLACE TABLE test_udf_outputs AS
    SELECT
      CAST(NULL AS TIMESTAMP) AS run_ts,
      CAST(NULL AS STRING) AS test_case_id,
      CAST(NULL AS STRING) AS notes,
      CAST(NULL AS STRING) AS result,
      CAST(NULL AS STRING) AS status
    WHERE FALSE;

    TestLoop: FOR row AS SELECT test_case_id, test_notes, test_sql, expected_result FROM test_udf_inputs WHERE test_case_number != 0 DO
      SET SQLTx = 'INSERT INTO test_udf_outputs SELECT '||
          'CURRENT_TIMESTAMP, '||
          '"'||row.test_case_id||'", '||
          '"'||row.test_notes||'", '||
          row.test_sql||' as result, '||
          'case when result '||row.expected_result||' then "PASS" else "FAIL" end as status';
      CatchErr: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
          BEGIN
            DECLARE cond STRING;
            DECLARE message STRING;
            DECLARE line INTEGER;
            GET DIAGNOSTICS CONDITION 1
              cond = CONDITION_IDENTIFIER,
              message = MESSAGE_TEXT,
              line = LINE_NUMBER;
            INSERT INTO test_udf_outputs
            SELECT
                CURRENT_TIMESTAMP,
                row.test_case_id,
                row.test_notes,
                'L'||string(line)||' : '||cond||' : '||message,
                CASE WHEN message LIKE '%'||trim(both '"' from regexp_replace(row.expected_result, r'^\s*=\s*', ''))||'%' THEN 'PASS' ELSE 'FAIL' END;
          END;
        EXECUTE IMMEDIATE SQLTx;
      END CatchErr;
      ITERATE TestLoop;
    END FOR TestLoop;

    SELECT
      i.test_case_subject,
      zeroifnull(sum(case when status = 'PASS' then 1 end)) as passes,
      zeroifnull(sum(case when status = 'FAIL' then 1 end)) as fails
    FROM test_udf_outputs o
      INNER JOIN test_udf_inputs i ON o.test_case_id = i.test_case_id
    GROUP BY 1
    ORDER BY 1;

END;


# Interrogate the test results in more detail
SELECT
   o.run_ts, o.test_case_id, o.notes, i.test_sql, i.expected_result, o.result, o.status
FROM test_udf_outputs o
  INNER JOIN test_udf_inputs i ON o.test_case_id = i.test_case_id
WHERE status = 'FAIL'
ORDER BY test_case_id;

