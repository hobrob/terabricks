#!/bin/bash
set -e

# Fail fast if required vars are missing
for var in DATABRICKS_HOST WAREHOUSE_ID DATABRICKS_TOKEN CATALOG_NAME SCHEMA_NAME; do
  [[ -z "${!var}" ]] && echo "Missing $var" && exit 1
done

# Inject parameters into SQL file (basic substitution)
SQL_TEMPLATE=$(<"$1")
SQL_RENDERED=$(echo "$SQL_TEMPLATE" \
  | sed "s/:catalog_name/$CATALOG_NAME/g" \
  | sed "s/:schema_name/$SCHEMA_NAME/g")

# Run SQL via REST API
curl -s -X POST "https://${DATABRICKS_HOST}/api/2.0/sql/statements/" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "statement": "'"$SQL_RENDERED"'",
    "warehouse_id": "'"$WAREHOUSE_ID"'",
    "wait_timeout": "30s"
  }'
