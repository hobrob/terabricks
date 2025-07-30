
DECLARE catalog_name STRING DEFAULT 'workspace';
DECLARE schema_name STRING DEFAULT 'default';
USE CATALOG IDENTIFIER(:catalog_name);
USE SCHEMA IDENTIFIER(:schema_name);

SHOW TABLES;
