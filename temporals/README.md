## terabricks-temporals

### Introduction

The [Teradata](https://www.teradata.com/) data warehouse platform implements a composite data type known as a [Period](https://docs.teradata.com/r/Lake-Working-with-SQL/SQL-Data-Types/Data-Types-and-Literals/Period-Data-Types) that consists of two values - a lower and upper bound of date, time, or timestamp types. This lends itself well to representing the validity of data over time as found in type 2, 4 and 6 [slowly changing dimension (SCD)](https://en.wikipedia.org/wiki/Slowly_changing_dimension) data structures.

Alongside the period type, it also offers a mature set of [functions and operators](https://docs.teradata.com/r/Lake-Working-with-SQL/SQL-Functions/SQL-Date-and-Time-Functions-and-Expressions/Period-Functions-and-Operators) for working with periods that simplify the sometimes complex interplay of predicates required to make sense of data as it changes over time, and does so in the verbose and intuitive style that is characteristic of SQL. The [Databricks](https://www.databricks.com/) lakehouse platform has emerged as a modern alternative to traditional data warehousing yet it has no such equivalent, so this project aims to fill that gap with a set of Unity Catalog UDFs authored in Python that replicate and extend much of this capability.  

<a id="000"></a>
### Table of Contents
🚀 [1.Getting Started](#001)<br />
&emsp;&emsp; [1.1.Option 1: Manual Deployment](#001_001)<br /> 
&emsp;&emsp; [1.2.Option 2: CI/CD Automated GitHub Workflow](#001_002)<br />
&emsp;&emsp; [1.3.Valid Period Formats](#001_003)<br />
&emsp;&emsp; [1.4.Examples](#001_004)<br />
🌐 [2.Overview](#002)<br />
⚠️[3.Type Handling, Precision, and Behavioral Differences](#003)<br /> 
🧩 [4.Extensions](#004)<br />
🧮 [5.Table of Functions and Operators](#005)<br />
🛣️️ [6.Roadmap](#006)<br />
🙏 [7. Support This Project](#007)

---

<a id="001"></a>
## 🚀 1. Getting Started

<a id="001_001"></a>
### 1.1. Option 1: Manual Deployment

For those who want to dive right in follow these steps to install and register the temporals UDFs in your Databricks workspace. Read on further below for more context and reference material.
<br /><br />
Replace the text between angled brackets <> with values that are applicable to your environment.  


1. **Clone the repository**
   ```bash
   git clone https://github.com/hobrob/terabricks
   cd terabricks
   ```
   
2. **Build the python wheel package**
   ```bash
   pip install build
   python -m build --wheel
   ```
   
3. **Upload the wheel to Unity Catalog**<br />
   Choose or create a target volume to host the wheel package and upload via the Unity Catalog UI, or from a python notebook cell:-
   ```bash
    dbutils.fs.cp("file:dist/terabricks_temporals-0.0.1-py3-none-any.whl", "dbfs:/Volumes/<catalog>/<schema>/<volume>/")
   ```
   Or from the Databricks cli:-
   ```bash
    databricks fs cp "dist/terabricks_temporals-0.0.1-py3-none-any.whl" "dbfs:/Volumes/<catalog>/<schema>/<volume>/"
   ```
   
4. **Upload the udf registration script**<br />
   Run sed to update the notebook with the volume path chosen in step 3 and the wheel name then it is ready to upload to a target workspace of your choosing.
   ```bash
   sed -i "s|__VOLUME__|/Volumes/<catalog>/<schema>/<volume>|g;s|__WHEEL__|terabricks_temporals-0.0.1-py3-none-any.whl|g" temporals/core/register_udfs.sql
   ```
   Upload to Databricks using the workspace UI, or from a python notebook cell
   ```bash
   dbutils.fs.cp("file:temporals/core/register_udfs.sql", "<workspace folder>")
   ```
   Or from the Databricks cli:-
   ```bash
   databricks fs cp "temporals/core/register_udfs.sql" "<workspace folder>"
   ```

5. **Run the UDF registration notebook**<br />
   You can use the Databricks UI or CLI but in both cases you must supply the target catalog and schema name via the named parameters catalog_name and schema_name. In Databricks CLI:-
   ```bash
   databricks jobs submit --json "{
     \"run_name\": \"Register Temporals UDFs\",
     \"tasks\": [{
       \"notebook_task\": {
         \"notebook_path\": \"/<workspace folder>/register_udfs\",
         \"base_parameters\": {
           \"env\": \"ci\",
           \"catalog_name\": \"<catalog>\",
           \"schema_name\": \"<schema>\"
         }
       }
     }]
   }"
   ```
   
6. **Verify UDFs are registered**<br />
    Run a test SQL query in Databricks SQL Editor or from an SQL notebook cell.
    ```SQL
    SELECT P_Intersect(Period('2025-05-01', '2025-07-01'), Period('2025-06-01', '2025-08-01'));
    ```
---

<a id="001_002"></a>
### 1.2. Option 2: CI/CD Automated GitHub Workflow

For teams using GitHub Actions, deployment can be fully automated via the provided `databricks-ci.yml` workflow. This approach eliminates manual steps and ensures reproducible UDF registration across environments.

#### Prerequisites

Before triggering the workflow, link your repo with Databricks UI by creating a Git folder and ensure the following GitHub secrets are configured in your repository:

| Secret Name             | Description                                                                                                                                          |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DATABRICKS_HOST`       | Your Databricks workspace URL (e.g. `https://dbc-1234abcd-5678.cloud.databricks.com`)                                                                |
| `DATABRICKS_TOKEN`      | Personal access token with workspace and volume write permissions (e.g.`dapi1234567890abcdef1234567890abcdef`)                                       |
| `WAREHOUSE_ID`          | An 8-byte hex string found in parentheses under the Name attribute in the SQL Warehouse Overview tab. (e.g.`1234567890abcdef`)                       |
| `WORKSPACE_REPO_ID`     | 16 digit numeric id found by clicking the branch name next to the git folder in workspace view, and go to the settings tab (e.g.`1234567890123456`)  |
| `WORKSPACE_USER_PATH`   | Your Databricks user home workspace path (e.g. `/Users/yo.ur@emailaddy.com`)                                                                         |
| `WORKSPACE_VOLUME_PATH` | The name of a volume path to host the python wheel and test data (e.g. `dbfs:/Volumes/my_workspace/my_schema/my_volume/volume_subdir`)               |
| `CATALOG_NAME`          | Target Unity Catalog name                                                                                                                            |
| `SCHEMA_NAME`           | Target schema within the catalog                                                                                                                     |

#### Triggering the Workflow

To deploy the UDFs via CI:

1. **Clone the repository**
   ```bash
   git clone https://github.com/hobrob/terabricks
   ```
2. **Push a commit to main**
   The workflow is triggered on push to the main branch. You can also force a run manually via the GitHub UI.
3. **Optional: Skip testing**
   The automated SQL testing module can take some time on smaller clusters, add [skip testsql] to the commit message to avoid this overhead.

---

<a id="001_003"></a>
### 1.3. Valid Period Formats
   Construct period values using the `Period(lower, upper)` constructor function. Both bounds must be ISO 8601-compliant strings of the same type and precision. The constructor validates the inputs once and returns a typed Period struct with an embedded UUID watermark — all subsequent UDF calls verify only the watermark rather than re-running full validation, giving significant performance gains when operating across millions of rows.

   Valid bound formats:
   ```sql
   '2025-06-01'                  -- date
   '12:34:56.789'                -- time with optional fractional seconds (1–6 decimal places)
   '2025-06-01 12:34:56.789'    -- timestamp with optional fractional seconds (1–6 decimal places)
   ```

   Timezone offsets are supported for time and timestamp types using the `+HH:MM`, `-HH:MM`, or `Z` suffix:
   ```sql
   '12:34:56+05:30'              -- time with UTC+5:30 offset
   '2025-06-01 12:34:56-04:00'  -- timestamp with UTC-4 offset
   '2025-06-01 08:00:00Z'       -- timestamp in UTC
   ```

   Both bounds must have the same type, the same fractional-second precision, and the same timezone offset (or both omit it). The upper bound must be strictly greater than the lower bound.
   ```sql
   Period('2025-06-01', '2025-06-02 12:34:56')  -- ❌ mixing types
   Period('12:34:56.7', '12:34:56.789')          -- ❌ mismatched precision
   Period('2025-06-01', '2025-06-32')            -- ❌ impossible date
   Period('2025-06-01', '2025-06-01')            -- ❌ upper bound not greater than lower
   Period('2025-06-01 08:00:00+01:00', '2025-06-30 08:00:00-04:00') -- ❌ mismatched timezone
   Period('2025-06-01', '2025-06-08')            -- ✅ valid 7-day period
   Period('08:00:00+05:30', '17:00:00+05:30')    -- ✅ valid time period with timezone
   ```

---

<a id="001_004"></a>
### 1.4. Examples
   Use the `Period()` constructor to create period values, then pass them to any of the UDFs.
   ```sql
SELECT 
        Period('2024-01-01', '2024-12-31') AS p, '2024-06-01' as t, 
        IsPeriod(p), Begin(p), End(p), Prior(t);

SELECT 
        Period('2025-01-01', '2025-12-31') AS p, 
        IsUntilChanged(p), IntervalD(p), IntervalH(p);
   ```
   Check if an instant falls within a period or meets its bounds. Check if two periods overlap, meet, or if one precedes the other.
   ```sql
SELECT 
        Period('2024-01-01', '2024-12-31') AS p, '2024-06-01' as t, 
        Contains(p, t), MeetsInstant(p, t);

SELECT 
        Period('2024-01-01', '2024-07-01') AS p1, Period('2024-07-01', '2024-12-31') as p2,
        Overlaps(p1, p2), MeetsPeriod(p1, p2), Precedes(p1, p2);
   ```
   Return a period that represents the overlap between two periods, or the gap between two periods.
   ```sql
SELECT 
        Period('2024-01-01', '2024-09-01') AS p1, Period('2024-07-01', '2024-12-31') as p2, Period('2025-03-01', '2025-12-31') as p3,
        P_Intersect(p1, p2), P_Intermediate(p2, p3);
   ```
   Use timezone-offset timestamps with `Period()` — all bounds must share the same offset.
   ```sql
SELECT Contains(Period('2025-06-01 08:00:00+05:30', '2025-06-30 08:00:00+05:30'), '2025-06-15 12:00:00+05:30');
   ```
---

<a id="overview"></a>
## 🌐 2. Overview

- Period types are a composite type consisting of two homogenously-typed date, time, or timestamp values.
- Hold an inclusive lower bound and exclusive upper bound.
- Sentinel “end” value for dates is 9999-12-31, for times 23:59:59.999999, and for timestamps it is the composite of these two values.
- Created using the `Period(lower, upper)` constructor function, which validates once and returns a struct with an embedded UUID watermark.

```sql
-- create a date, time, and timestamp-ranged period
SELECT Period('2025-01-01', '2026-01-01'), Period('13:50:00.00', '14:10:00.00'), Period('2025-01-01 13:50:00.00', '2026-01-01 14:10:00.00');
```
The set of functions and operators that accompany the period data type can be broadly categorised into four areas:
- Informational - return information about the type such as the beginning or end bound, or the duration.
- Sequencing - Compare two periods or points in time and return boolean values indicating their presence in relation to one another, such as Precedes() which returns true if a period occurs before another.
- Set operations - These return a period object based on a set operation carried out on two periods, such as P_Intersect, that returns a period representing the overlap between two periods. 
- Table functions - These can be used in the context of an SQL from clause to expand period types row-wise into table-like structures. These are currently out of scope of this project but may be explored in the future.   

---

<a id="003"></a>
## ⚠️ 3. Type Handling, Precision, and Behavioral Differences

#### Data Types

The set of operators and functions available on Teradata are able to accept any of the three distinct data types that can be found within a period - date, time, or timestamp. Since UDFs are strongly typed, i.e. they must explicitly declare a single data type for each argument, it is necessary to instead use a data type that can accommodate all three types and therefore strings validated as containing ISO 8601 compliant formats are expected and returned wherever they would be found on Teradata.

To emulate the composite nature of the period type, Terabricks uses a `Period(lower, upper)` constructor UDF that validates the two bound strings once and returns a typed struct `STRUCT<lower: STRING, upper: STRING, period_id: STRING>`. The `period_id` field carries a fixed UUID watermark so that all other UDFs can confirm the value was produced by the constructor with a single equality check, eliminating per-row regex validation overhead.

#### 1 to 1 Function Mapping

While most of the Teradata functions and operators have a 1 to 1 mapping to the UDFs, the strongly typed nature of UDFs also means that functions that accept or return a variety of types require more than one alternative in Databricks. Specifically, the MEETS operator can take either a period or a single point-in-time as the second argument, and to accommodate this Terabricks provide two alternatives - MeetsPeriod() and MeetsInstant(). The INTERVAL operator can return any of the multiple interval types, and as such a separate UDF is required for each interval type. See the table in section 5 for more details. 

#### Precision

Time and timestamp types in Teradata have strongly typed precision whereas Databricks does not, but both Teradata and Databricks pad the precision of the seconds component with zeroes to 6 decimal places if not supplied. For comparison operations, Teradata does not impose any requirement that the precision of the values being compared must match but the Terabricks MVP does. This restriction will be relaxed in subsequent versions.  

#### Timezone Awareness

Time and timestamp bound values may include a UTC offset suffix in `+HH:MM`, `-HH:MM`, or `Z` (UTC) format. Both bounds of a period must carry the same offset (or both omit it entirely), and any instant passed to a period UDF must match the period's offset. The `Period()` constructor enforces these constraints at construction time; subsequent UDF calls rely on the UUID watermark and therefore incur no extra timezone-checking overhead.

Date bounds never carry timezone information.

---

<a id="004"></a>
## 🧩 4. Extensions

The full set of informational, sequencing, and set operation functions and operators have all been replicated in some form or another, but some additional functions are also provided to extend the functionality available in Teradata.<br />

| Function                  | Description                                                                                         |
|---------------------------|-----------------------------------------------------------------------------------------------------|
| `Period(lower, upper)`    | Constructor that validates bounds once and returns a Period struct with a UUID watermark.            |
| `IsPeriod(p)`             | Returns true if `p` is a valid Period struct created by the `Period()` constructor.                 |
| `Consumes(p1, p2)`        | Checks if `p1` is at least equal to or fully engulfs `p2`.                                         |
| `OverlapsLeft(p1, p2)`    | Tests if `p1` overlaps `p2` with a portion of `p1` occurring before `p2`.                          |
| `OverlapsRight(p1, p2)`   | Tests if `p1` overlaps `p2` with a portion of `p1` occurring after `p2`.                           |
| `P_Intermediate(p1, p2)`  | Returns the gap period between `p1` and `p2` if they don’t overlap or touch.                  |
---

<a id="005"></a>
## 🧮 5. Table of Functions and Operators

In the following table the placeholders p, p1, and p2 represent periods and t represents point-in-time instants. For the Terabricks equivalent UDFs, where a return type of DATE/TIME/TIMESTAMP is given this actually equates to an ISO 8601 compliant string, and PERIOD equates to a Period struct returned by the `Period()` constructor. 

| Category       | Teradata Usage                 | Terabricks Usage                              | Return Type               | Notes                                                                                                                         |
|----------------|--------------------------------|-----------------------------------------------|---------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| Informational  | n/a                            | `IsPeriod(p)`                                 | BOOLEAN                   |                                                                                                                               |
| Informational  | `BEGIN(p)`                     | `Begin(p)`                                    | DATE/TIME/TIMESTAMP       |                                                                                                                               |
| Informational  | `END(p)`                       | `End(p)`                                      | DATE/TIME/TIMESTAMP       |                                                                                                                               |
| Informational  | `LAST(p)`                      | `Last(p)`                                     | DATE/TIME/TIMESTAMP       |                                                                                                                               |
| Informational  | `NEXT(t)`                      | `Next(t)`                                     | DATE/TIME/TIMESTAMP       |                                                                                                                               |
| Informational  | `PRIOR(t)`                     | `Prior(t)`                                    | DATE/TIME/TIMESTAMP       |                                                                                                                               |
| Informational  | `INTERVAL(p) YEAR`             | `IntervalYear(p)`, `IntervalY(p)`             | INTERVAL YEAR             |                                                                                                                               |
| Informational  | `INTERVAL(p) YEAR TO MONTH`    | `IntervalYearToMonth(p)`, `IntervalY2M(p)`    | INTERVAL YEAR TO MONTH    |                                                                                                                               |
| Informational  | `INTERVAL(p) MONTH`            | `IntervalMonth(p)`, `IntervalMo(p)`           | INTERVAL MONTH            |                                                                                                                               |
| Informational  | `INTERVAL(p) DAY`              | `IntervalDay(p)`, `IntervalD(p)`              | INTERVAL DAY              |                                                                                                                               |
| Informational  | `INTERVAL(p) DAY TO HOUR`      | `IntervalDayToHour(p)`, `IntervalD2H(p)`      | INTERVAL DAY TO HOUR      |                                                                                                                               |
| Informational  | `INTERVAL(p) DAY TO MINUTE`    | `IntervalDayToMinute(p)`, `IntervalD2M(p)`    | INTERVAL DAY TO MINUTE    |                                                                                                                               |
| Informational  | `INTERVAL(p) DAY TO SECOND`    | `IntervalDayToSecond(p)`, `IntervalD2S(p)`    | INTERVAL DAY TO SECOND    |                                                                                                                               |
| Informational  | `INTERVAL(p) HOUR`             | `IntervalHour(p)`, `IntervalH(p)`             | INTERVAL HOUR             |                                                                                                                               |
| Informational  | `INTERVAL(p) HOUR TO MINUTE`   | `IntervalHourToMinute(p)`, `IntervalH2M(p)`   | INTERVAL HOUR TO MINUTE   |                                                                                                                               |
| Informational  | `INTERVAL(p) HOUR TO SECOND`   | `IntervalHourToSecond(p)`, `IntervalH2S(p)`   | INTERVAL HOUR TO SECOND   |                                                                                                                               |
| Informational  | `INTERVAL(p) MINUTE`           | `IntervalMinute(p)`, `IntervalMi(p)`          | INTERVAL MINUTE           |                                                                                                                               |
| Informational  | `INTERVAL(p) MINUTE TO SECOND` | `IntervalMinuteToSecond(p)`, `IntervalM2S(p)` | INTERVAL MINUTE TO SECOND |                                                                                                                               |
| Informational  | `INTERVAL(p) SECOND`           | `IntervalSecond(p)`, `IntervalS(p)`           | INTERVAL SECOND           |                                                                                                                               || Informational  | IS UNTIL_CHANGED           | IsUntilChanged(p)                         | BOOLEAN                   |                                                                                                                                    |
| Informational  | `IS UNTIL_CHANGED`             | `IsUntilChanged(p)`                           | BOOLEAN                   |                                                                                                                               |
| Informational  | `IS NOT UNTIL_CHANGED`         | n/a                                           | BOOLEAN                   | Use IsUntilChanged() with a negation operator                                                                                 |
| Sequencing     | n/a                            | `Consumes(p1, p2)`                            | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p CONTAINS t`                 | `Contains(p, t)`                              | BOOLEAN                   | Must be qualified with a schema name to avoid conflict with its namesake built-in function                                    |
| Sequencing     | `p1 EQUALS p2`                 | `Equals(p1, p2)`                              | BOOLEAN                   | The equality operator (=) achieves the same outcome for far fewer keystrokes, but the UDF is still included for completeness. |
| Sequencing     | `p1 OVERLAPS p2`               | `Overlaps(p1, p2)`                            | BOOLEAN                   |                                                                                                                               |
| Sequencing     | n/a                            | `OverlapsLeft(p1, p2)`                        | BOOLEAN                   |                                                                                                                               |
| Sequencing     | n/a                            | `OverlapsRight(p1, p2)`                       | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p MEETS t`                    | `MeetsInstant(p, t)`                          | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p1 MEETS p2`                  | `MeetsPeriod(p1, p2)`                         | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p1 PRECEDES p2`               | `Precedes(p1, p2)`                            | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p1 IMMEDIATELY PRECEDES p2`   | `ImmediatelyPrecedes(p1, p2)`                 | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p1 SUCCEEDS p2`               | `Succeeds(p1, p2)`                            | BOOLEAN                   |                                                                                                                               |
| Sequencing     | `p1 IMMEDIATELY SUCCEEDS p2`   | `ImmediatelySucceeds(p1, p2)`                 | BOOLEAN                   |                                                                                                                               |
| Set operations | `p1 LDIFF p2`                  | `LDiff(p1, p2)`                               | PERIOD                    |                                                                                                                               |
| Set operations | `p1 RDIFF p2`                  | `RDiff(p1, p2)`                               | PERIOD                    |                                                                                                                               |
| Set operations | `p1 P_INTERSECT p2`            | `P_Intersect(p1, p2)`                         | PERIOD                    |                                                                                                                               |
| Set operations | n/a                            | `P_Intermediate(p1, p2)`                      | PERIOD                    |                                                                                                                               |

---

<a id="006"></a>
## 🛣️️ 6. Roadmap

This is a wishlist of things that will be added in future releases on a best endeavours basis.

- [ ] Permissive Precision Handling - Functions that enforce precision parity will be relaxed to allow times and timestamps of varying precision to be compared.
- [x] Timezone awareness - Time and timestamp values may include UTC offsets (`+HH:MM`, `-HH:MM`, `Z`). Both bounds of a period and any instant must share the same offset.
- [ ] Table functions - A full interpretation of the set of function prefixed with TD_ is desirable, though may be difficult to implement in Unity Catalog due to a limitation whereby only scalar UDFs are allowed.  
- [x] Optimize period validation - The `Period(lower, upper)` constructor validates once and embeds a UUID watermark into a typed struct. All other UDFs perform a single equality check against the watermark rather than re-running regex validation, eliminating per-row overhead at scale.

Contributions are welcome, please see [CONTRIBUTIONS.md]() for more info.


## 🙏 7. Support This Project

If you find this project helpful, inspiring, or just plain cool, consider supporting its development. Your contributions help keep the lights on and the ideas flowing.

### Buy Me a Coffee
You can make a small donation via [BuyMeACoffee](https://buymeacoffee.com/hobrob) — every cup fuels more code!

### Crypto Donations 
Prefer crypto? You’re awesome, I do too! Here are some wallet addresses:

- **₿ Bitcoin (BTC):** `bc1qszqvuczfj7h26jv57kacwlyqn5z7ptdmnlpdpp`
- **Ł Litecoin (LTC):** `MGxDKMDwrWLXJxuxjnuPiBnQHkGKXyBpcS`
- **Ξ Ethereum (ETH):** `0xbE9056cB36f741FcB50c1d49b700cDA6dbdc614c`

### Other Ways to Support 
- Share the repo with others who might benefit
- Star ⭐ the project on GitHub
- Open an issue or PR to help improve it

---
[Back to top](#000)
