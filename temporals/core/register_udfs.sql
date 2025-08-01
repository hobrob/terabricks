-- Databricks notebook source

USE CATALOG IDENTIFIER(:catalog_name);
USE CATALOG IDENTIFIER(:schema_name);
SELECT current_catalog(), :catalog_name, current_schema(), :schema_name;
SELECT current_date();
SELECT current_user();
