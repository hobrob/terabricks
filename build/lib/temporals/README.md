## terabricks-temporals

### Introduction

The Teradata data warehouse platform implements a composite data type known as a Period that consists of two values - a lower and upper bound of date, time, or timestamp types. This lends itself well to representing the validity of data over time as found in type 2, 4 and 6 slowly changing dimension (SCD) data structures.

Alongside the period type, it also offers a mature set of functions and operators that simplify the sometimes complex interplay of predicates required to make sense of data over time, and does so in the verbose and intuitive style that is typical of SQL. Databricks has no such equivalent, so this project aims to fill that gap with a set of Unity Catalog UDFs authored in Python that replicate and extend much of this capability.  

### Table of Contents
1. Getting Started
2. Overview
3. Limitations and Differences
4. Extensions
5. Table of Functions and Operators
6. Roadmap