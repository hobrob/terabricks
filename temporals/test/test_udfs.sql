-- Databricks notebook source
-- MAGIC %md
-- MAGIC ## 🧱 Step 1: DDL
-- MAGIC Initialise the working catalog and schema, then create a view over testing source data and a target table for test results.

-- COMMAND ----------

USE CATALOG IDENTIFIER(:catalog_name);
USE SCHEMA IDENTIFIER(:schema_name);

CREATE OR REPLACE VIEW test_udf_inputs as
SELECT concat(TestCaseSubject, '_', lpad(string(TestCaseNumber), 3, '0')) AS TestCaseId, t.*
FROM read_files(
  'dbfs:__VOLUME__/__TEST_DATA__',
  format => 'csv',
  header => 'true',
  delimiter => '|') t;

CREATE OR REPLACE TABLE test_udf_outputs AS
SELECT
  CAST(NULL AS TIMESTAMP) AS RunTs,
  CAST(NULL AS STRING) AS TestCaseId,
  CAST(NULL AS STRING) AS Result,
  CAST(NULL AS STRING) AS Status
WHERE FALSE;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⏳ Step 2: Run test cases
-- MAGIC This procedure loops through each row of the input view and runs the SQL string - a function call with parameters testing various scenarios.
-- MAGIC Successful results are logged immediately and errors are caught and also logged, in both cases the outcome is compared against the expected result and given a pass or fail.

-- COMMAND ----------

BEGIN

    DECLARE SQLTx STRING DEFAULT '';

    TestLoop: FOR row AS SELECT TestCaseId, TestNotes, TestSQL, ExpectedResult FROM test_udf_inputs ORDER BY TestCaseId DO
      SET SQLTx = 'INSERT INTO test_udf_outputs SELECT '||
          'CURRENT_TIMESTAMP AS RunTs, '||
          '"'||row.TestCaseId||'", '||
          row.TestSQL||' AS Result, '||
          'case when Result '||row.ExpectedResult||' then "PASS" else "FAIL" end as Status';
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
                row.TestCaseId,
                'L'||string(line)||' : '||cond||' : '||message,
                CASE WHEN message LIKE '%'||trim(both '"' from regexp_replace(row.ExpectedResult, r'^\s*=\s*', ''))||'%' THEN 'PASS' ELSE 'FAIL' END;
          END;
        EXECUTE IMMEDIATE SQLTx;
      END CatchErr;
      ITERATE TestLoop;
    END FOR TestLoop;

END;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🔍 Step 3: Inspect results
-- MAGIC Two extracts, the first is a subject-level summary of test results, the second reports all of the failures at a test case-level.

-- COMMAND ----------

SELECT
  i.TestCaseSubject,
  zeroifnull(sum(case when status = 'PASS' then 1 end)) as passes,
  zeroifnull(sum(case when status = 'FAIL' then 1 end)) as fails
FROM test_udf_outputs o
  INNER JOIN test_udf_inputs i ON o.TestCaseId = i.TestCaseId
GROUP BY 1
ORDER BY 1;

SELECT
   o.RunTs, o.TestCaseId, i.TestNotes, i.TestSQL, i.ExpectedResult, o.Result, o.Status
FROM test_udf_outputs o
  INNER JOIN test_udf_inputs i ON o.TestCaseId = i.TestCaseId
WHERE status = 'FAIL'
ORDER BY TestCaseId;
