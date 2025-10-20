# ms2pg: MS SQL to PostgreSQL Migration Tool

`ms2pg` is a comprehensive, schema-driven command-line tool for migrating databases from Microsoft SQL Server to PostgreSQL. It uses a sophisticated, multi-stage pipeline to ensure high fidelity and correctness:

1.  **Scripts** the MS SQL database schema using SQL Server Management Objects (SMO).
2.  **Parses** the T-SQL scripts into an Abstract Syntax Tree (AST) using `Microsoft.SqlServer.TransactSql.ScriptDom`.
3.  **Serializes** this AST into an intermediate XML representation.
4.  **Transforms** the XML into PostgreSQL-compatible SQL using a powerful and extensible set of XSLT stylesheets.
5.  **Deploys** the generated scripts to PostgreSQL, complete with an advanced error-handling and auto-correction mechanism.
6.  **Migrates** data efficiently using PostgreSQL's `COPY BINARY` command.

---

## Table of Contents

-   [Features](https://www.google.com/search?q=%23features)
-   [How it Works: The Migration Pipeline](https://www.google.com/search?q=%23how-it-works-the-migration-pipeline)
-   [Configuration](https://www.google.com/search?q=%23configuration)
    -   [Main `config.xml` Structure](https://www.google.com/search?q=%23main-configxml-structure)
    -   [Property Definition](https://www.google.com/search?q=%23property-definition)
    -   [Configuration Parameters](https://www.google.com/search?q=%23configuration-parameters)
    -   [Action-Specific Properties](https://www.google.com/search?q=%23action-specific-properties)
-   [Key Transformation Logic (XSLT)](https://www.google.com/search?q=%23key-transformation-logic-xslt)
-   [Data Migration](https://www.google.com/search?q=%23data-migration)
-   [Deployment & Error Handling](https://www.google.com/search?q=%23deployment--error-handling)
-   [Prerequisites](https://www.google.com/search?q=%23prerequisites)
-   [How to Run](https://www.google.com/search?q=%23how-to-run)

---

## Features

-   **Full Schema Migration**: Converts tables, views, functions, stored procedures, indexes, and constraints.
-   **AST-Based Transformation**: Uses Microsoft's official `ScriptDom` parser, not brittle regex, for accurate T-SQL analysis.
-   [cite\_start]**Extensible XSLT Logic**: All transformation logic is defined in `.xslt` files[cite: 138], allowing for customization without recompiling the C\# application.
-   [cite\_start]**High-Performance Data Copy**: Migrates data using `NpgsqlConnection.BeginBinaryImport` (the equivalent of `COPY ... FROM STDIN (FORMAT BINARY)`), which is the fastest way to load data into PostgreSQL[cite: 8].
-   [cite\_start]**Intelligent Procedure Conversion**: Automatically converts T-SQL stored procedures that return a result set into PostgreSQL `FUNCTION ... RETURNS TABLE (...)`[cite: 117, 120].
-   [cite\_start]**Advanced Error Solver**: The deployment engine can automatically fix common PostgreSQL errors (like type mismatches, syntax errors, or dependency issues) and retry failed batches[cite: 10].
-   [cite\_start]**Post-Deployment Validation**: Automatically uses the `plpgsql_check` extension to validate the correctness of created functions and procedures, reporting the _actual_ in-function error, not just `CREATE FUNCTION` failure[cite: 10, 11, 126].
-   **Complex T-SQL Support**: Includes translations for:
    -   [cite\_start]`CROSS APPLY` / `OUTER APPLY` to `INNER JOIN LATERAL` / `LEFT JOIN LATERAL`[cite: 62, 63].
    -   [cite\_start]`FOR XML` queries to PostgreSQL's `xmlelement`, `xmlagg`, and `xmlforest` functions[cite: 37].
    -   [cite\_start]`OBJECT_ID`, `GETDATE()`, `NEWID()`, `ISNULL`, `DATEADD`/`DATEDIFF`, and many other T-SQL built-in functions[cite: 84, 85, 86, 87, 91].
-   [cite\_start]**Configurable Pipeline**: All steps are defined and controlled via a central `config.xml` file[cite: 9].

---

## How it Works: The Migration Pipeline

[cite\_start]The tool operates as a series of "actions" defined in the `config.xml` file[cite: 4, 9]. Each action performs a distinct step of the migration.

1.  [cite\_start]**`ClearFolder`**: (Optional) Cleans a directory before a run[cite: 4].
2.  **`ScriptMsSql`**: Connects to the MS SQL server using the provided connection string and SMO. [cite\_start]It scripts all database objects (tables, views, procedures, etc.) into individual `.sql` files in the `ms-script-dir`[cite: 4, 13].
3.  [cite\_start]**`ParseMsSql`**: Reads every `.sql` file from `ms-parsed-dir`, parses it into a T-SQL AST using `ScriptDom`, and then saves the AST as a `.xml` file[cite: 2, 4]. This XML represents the _logic_ of the MS SQL script.
4.  **`ScriptPgSql`**: Reads every `.xml` file from `ms-parsed-dir`. [cite\_start]It applies the main XSLT transform (`xslt-file-name`) to each one, generating a PostgreSQL-compatible `.sql` script in `pg-script-dir`[cite: 4, 11].
5.  **`DeployPgSql`**: Connects to the target PostgreSQL database. It reads the `.sql` files from `pg-script-dir` in the order specified by `pg-deploy-dir-sequence` (e.g., schemas first, then tables, then views...). [cite\_start]It executes each script batch by batch, using the [Error Handling](https://www.google.com/search?q=%23deployment--error-handling) engine to manage failures[cite: 4, 10].
6.  [cite\_start]**`FormatMsSql`**: (Mentioned in `ConfigAction.cs`) [cite: 4] A step for formatting T-SQL files.

---

## Configuration

[cite\_start]The entire migration process is controlled by a central `config.xml` file, which is loaded by default[cite: 6, 9].

### Main `config.xml` Structure

[cite\_start]The XML file has two main sections: `<common>` for properties shared by all actions, and `<actions>` for the specific pipeline steps[cite: 9].

```xml
<?xml version="1.0" encoding="utf-8"?>
<ms2pg-config>
  <common>
    <property name="ms-connection-string" value="Server=..."/>
    <property name="pg-connection-string" variable="PG_CONN_STRING"/>
    <property name="base-dir" value="C:\Migration"/>
    <property name="ms-script-dir" property-value="base-dir" />
  </common>

  <actions>
    <action name="Script MS SQL" type="script-ms-sql" enabled="true">
      <property name="file-name-contains-filters" value="dbo.Users,dbo.Orders"/>
    </action>

    <action name="Parse MS SQL" type="parse-ms-sql" enabled="true" />

    <action name="Script PG SQL" type="script-pg-sql" enabled="true">
       <property name="xslt-file-name" value="xslt/ms2pg.xslt"/>
    </action>

    <action name="Deploy PG SQL" type="deploy-pg-sql" enabled="true">
      <property name="pg-deploy-dir-sequence" value="Schema,Table,View,Function,Procedure"/>
    </action>
  </actions>
</ms2pg-config>
```

### Property Definition

[cite\_start]Properties are key-value pairs used by the actions[cite: 9]. They can be defined in three ways:

1.  [cite\_start]**By Value**: `name="key" value="literal_value"` [cite: 9]
2.  [cite\_start]**By Environment Variable**: `name="key" variable="ENV_VAR_NAME"` [cite: 9]
3.  [cite\_start]**By Reference**: `name="key" property-value="other_common_property_name"` [cite: 9]

### Configuration Parameters

This table lists all parameters recognized by the application, found across all C\# files.

| Parameter                             | Used By                                                           | Description                                                                                                                                                                           |
| ------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ms-connection-string`                | `script-ms-sql`, `DataMigration`, `XsltExtensions`                | Connection string for the source MS SQL Server.                                                                                                                                       |
| `pg-connection-string`                | `deploy-pg-sql`, `DataMigration`, `ErrorsSolver`                  | Connection string for the target PostgreSQL database.                                                                                                                                 |
| `ms-script-dir`                       | `script-ms-sql`                                                   | [cite\_start]**Output** directory for `.sql` files scripted from MS SQL[cite: 13].                                                                                                    |
| `ms-parsed-dir`                       | `parse-ms-sql`, `script-pg-sql`                                   | **Input/Output** directory. [cite\_start]`parse-ms-sql` writes `.xml` files here[cite: 2]. [cite\_start]`script-pg-sql` reads them[cite: 11].                                         |
| `pg-script-dir`                       | `script-pg-sql`, `deploy-pg-sql`                                  | **Input/Output** directory. [cite\_start]`script-pg-sql` writes final PG-compatible `.sql` files here[cite: 11]. [cite\_start]`deploy-pg-sql` reads them[cite: 10].                   |
| `xslt-file-name`                      | `script-pg-sql`                                                   | [cite\_start]**Required.** The path to the main XSLT file (e.g., `ms2pg.xslt`)[cite: 11].                                                                                             |
| `pg-deploy-dir-sequence`              | `deploy-pg-sql`                                                   | **Required.** A comma-separated list of subdirectories _in order_ for deployment. [cite\_start]This controls dependency resolution (e.g., `Schema,Table,Function,View`)[cite: 10].    |
| `deploy-retry-count`                  | `deploy-pg-sql`                                                   | The maximum number of errors to tolerate before aborting the deployment. [cite\_start]Default is 1000[cite: 10].                                                                      |
| `file-name-contains-filters`          | `parse-ms-sql`, `script-ms-sql`, `script-pg-sql`, `deploy-pg-sql` | Optional. A comma-separated list of strings. The tool will only process files whose names contain one of these strings. [cite\_start]Used for testing/filtering[cite: 2, 10, 11, 14]. |
| `is-debug-messages`                   | `parse-ms-sql`                                                    | [cite\_start]Set to `"true"` to enable verbose console logging from the `XmlSerializer`[cite: 2].                                                                                     |
| `is-xml-enumerables-name-like-parent` | `parse-ms-sql`                                                    | [cite\_start]Set to `"true"` for a specific `XmlSerializer` naming convention[cite: 2].                                                                                               |
| `excluded-properties`                 | `parse-ms-sql`                                                    | [cite\_start]A comma-separated list of property names to exclude from the XML serialization (e.g., `FirstTokenIndex`)[cite: 2].                                                       |

### Action-Specific Properties

These properties are read from within an `<action>` block.

| Action Type    | Property  | Description                                                                             |
| -------------- | --------- | --------------------------------------------------------------------------------------- |
| `clear-folder` | `dir`     | [cite\_start]The directory path to empty[cite: 4].                                      |
| `clear-folder` | `exclude` | (Optional) [cite\_start]A comma-separated list of sub-folders to _not_ delete[cite: 4]. |

---

## Key Transformation Logic (XSLT)

The core of the translation logic resides in the `.xslt` files. [cite\_start]The main entry point is `ms2pg.xslt`[cite: 138], which imports all other stylesheets (`createtable.xslt`, `createfunction.xslt`, `select.xslt`, etc.).

The transformation is applied to the XML representation of the T-SQL AST.

**Key Translations:**

-   [cite\_start]**`CREATE PROCEDURE`**[cite: 117]:
    -   [cite\_start]If the `XsltExtensions` class detects the procedure has a result set (by querying `sys.dm_exec_describe_first_result_set_for_object`), it's converted to a `CREATE OR REPLACE FUNCTION ... RETURNS TABLE (...)`[cite: 17, 120].
    -   [cite\_start]If it has no result set, it becomes a `CREATE OR REPLACE PROCEDURE (...)`[cite: 118].
    -   [cite\_start]`OUTPUT` parameters are converted to `INOUT`[cite: 119].
-   [cite\_start]**`CREATE FUNCTION`**[cite: 1]:
    -   Converted to `CREATE OR REPLACE FUNCTION`.
    -   [cite\_start]T-SQL "inline table-valued functions" (`RETURNS TABLE AS SELECT ...`) are converted using `ms2pg:GetTableValuedFunctionTableDefinition` to fetch the schema and build a `RETURNS TABLE (...)` definition[cite: 4].
-   [cite\_start]**`SELECT` Statements**[cite: 24]:
    -   [cite\_start]`FOR XML` is translated into a complex structure of `xmlelement`, `xmlagg`, `xmlattributes`, and `xmlforest` calls[cite: 37, 38, 40].
    -   [cite\_start]`CROSS APPLY` is translated to `INNER JOIN LATERAL`[cite: 62].
    -   [cite\_start]`OUTER APPLY` is translated to `LEFT JOIN LATERAL`[cite: 63].
-   [cite\_start]**Data Types**[cite: 15]:
    -   [cite\_start]`DATETIME` -\> `TIMESTAMP(3)` [cite: 16]
    -   [cite\_start]`SMALLDATETIME` -\> `TIMESTAMP(0)` [cite: 19]
    -   [cite\_start]`BIT` -\> `INT2` [cite: 16]
    -   [cite\_start]`TINYINT` -\> `INT2` [cite: 19]
    -   [cite\_start]`UNIQUEIDENTIFIER` -\> `UUID` [cite: 19]
    -   [cite\_start]`NVARCHAR(MAX)` / `VARCHAR(MAX)` -\> `TEXT` [cite: 18, 20]
    -   [cite\_start]`NTEXT` / `TEXT` -\> `TEXT` [cite: 18, 19]
    -   [cite\_start]`IMAGE` / `VARBINARY` / `ROWVERSION` -\> `BYTEA` [cite: 16, 17, 19, 20]
-   [cite\_start]**Expressions**[cite: 73]:
    -   [cite\_start]`GETDATE()` -\> `now()` [cite: 91]
    -   [cite\_start]`NEWID()` -\> `public.uuid_generate_v4()` [cite: 91]
    -   [cite\_start]`ISNULL(a, b)` -\> `COALESCE(a, b)` [cite: 91]
    -   [cite\_start]`DATEADD(part, num, date)` -\> `date + INTERVAL 'num part'` [cite: 85]
    -   [cite\_start]`DATEDIFF(part, start, end)` -\> `dbo.DateDiff('part', start, end)` (uses the prerequisite function) [cite: 86]
    -   [cite\_start]`OBJECT_ID('name')` -\> `to_regclass('name')` [cite: 87]
    -   [cite\_start]`CHARINDEX(a, b)` -\> `strpos(b, a)` [cite: 89, 90]
    -   [cite\_start]`@@SERVERNAME` -\> `CAST(inet_server_addr() AS VARCHAR)` [cite: 109]
    -   [cite\_start]`@@ROWCOUNT` -\> `pg_affected_rows()` [cite: 109]
-   **Validation**: After creating a function or procedure, the XSLT appends a `DO` block that calls `public.plpgsql_check_function_tb`. [cite\_start]If errors are found, it raises an exception with the prefix `{{CHECK ERROR}}`, which the `ErrorsSolver` class intercepts[cite: 10, 11, 128].

---

## Data Migration

[cite\_start]Data migration is handled by the `DataMigration.cs` class [cite: 8] (it is not part of the standard `ConfigAction` pipeline and may need to be triggered separately).

1.  [cite\_start]**`EnlistAllTables`**: This static method reads the `sqlscripts/TablesDependencies.sql` file[cite: 7, 8]. This query lists all tables, ordered by their dependencies and size, to ensure data is loaded in the correct order (parent tables before child tables).
2.  **`MigrateTableData`**: This method handles the migration for a single table.
    -   [cite\_start]It opens a connection to both MS SQL (`SqlConnection`) and PostgreSQL (`NpgsqlConnection`)[cite: 8].
    -   [cite\_start]It issues a `DELETE FROM {tableName};` to the PostgreSQL table[cite: 8].
    -   [cite\_start]It reads all data from the MS SQL table using `SqlCommand.ExecuteReader`[cite: 8].
    -   [cite\_start]It loads data into a `DataTable` in batches of 100 rows[cite: 8].
    -   [cite\_start]When the batch is full, `FlushDataTable` is called, which uses `NpgsqlConnection.BeginBinaryImport` to stream the data efficiently to PostgreSQL using `COPY ... FROM STDIN (FORMAT BINARY)`[cite: 8].

---

## Deployment & Error Handling

[cite\_start]The `PgDeploy.cs` class provides a robust deployment engine[cite: 10].

-   **Batch Execution**: It reads all `.sql` files specified by the `pg-deploy-dir-sequence` configuration. [cite\_start]Each file is split into batches using `{{GO}}` as a delimiter[cite: 10].
-   **Error Queue**: When a batch fails with a `PostgresException`, it is not immediately aborted. [cite\_start]Instead, the exception and the batch are passed to `ErrorsSolver.Solve`[cite: 10].
-   **Retry Loop**: If the error is solvable or deemed a temporary dependency issue (`Unsolved`), the batch is re-added to the _end_ of a retry queue. The deployer continues executing other batches, hoping the dependencies will be resolved. [cite\_start]It will retry the failed batch on the next pass[cite: 10].
-   **Deadlock Detection**: The deployer calculates a hash of the current error queue. [cite\_start]If the hash remains the same for more iterations than there are items in the queue, it assumes a permanent, unresolvable loop (e.g., circular dependency) and aborts, writing the failed batches to `errors.sql`[cite: 10].

**ErrorsSolver.cs**

This is the "magic" of the deployer. [cite\_start]It's a large `switch` statement on the `PostgresException.SqlState` (the SQL error code) that attempts to fix common migration errors _automatically_[cite: 10].

-   `42883` (Operator does not exist):
    -   Fixes `varchar + varchar` to `varchar || varchar`.
    -   Fixes `int = 'text'` by adding a `CAST`.
    -   Fixes `timestamp - int` to `timestamp - INTERVAL '...'`.
-   `22007` (Invalid datetime format):
    -   Replaces `''` with `null` if it detects an invalid cast to timestamp.
-   `42P16` (Multiple view definitions):
    -   Adds `DROP VIEW IF EXISTS ...;` before the `CREATE VIEW` statement.
-   `42809` / `42P13` (Function signature mismatch):
    -   Adds `DROP FUNCTION IF EXISTS ...;` and `DROP PROCEDURE IF EXISTS ...;` before the statement to handle signature changes.
-   `{{CHECK ERROR}}` (Custom error from `plpgsql_check`):
    -   This is a custom error raised by the XSLT. [cite\_start]The solver re-connects to PostgreSQL and queries `public.plpgsql_check_function_tb` to get the _real_ error (e.g., "variable not found") and its line number, providing a much clearer debugging message[cite: 10].

If an error is fixed, the batch is modified in-place and re-run. [cite\_start]If it's unfixable (`Unsolvable`), it's logged to `errors.sql`[cite: 10].

---

## Prerequisites

For the migration to succeed, the **target PostgreSQL database** must have the following extensions and objects created. [cite\_start]This is handled by running the `prerequsites.sql` script[cite: 7].

1.  **Extensions**:
    -   [cite\_start]`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";` (for `NEWID()` translation)[cite: 7].
    -   [cite\_start]`CREATE EXTENSION IF NOT EXISTS plpgsql_check;` (for function validation)[cite: 7].
2.  **Schema**:
    -   [cite\_start]`CREATE SCHEMA IF NOT EXISTS dbo;` (to act as the default schema)[cite: 7].
    -   [cite\_start]`ALTER DATABASE ... SET SEARCH_PATH = dbo;` (to mimic MS SQL's default behavior)[cite: 7].
3.  **Custom Function**:
    -   A `dbo.DateDiff` function must be created. [cite\_start]The `prerequsites.sql` file contains the full `plpgsql` definition for this function, which emulates the behavior of T-SQL's `DATEDIFF`[cite: 7].

---

## How to Run

The application is a standard .NET console app.

1.  Ensure you have a `config.xml` file in the working directory (or specify a path).
2.  Run the application:

<!-- end list -->

```bash
# Runs using the default config.xml
dotnet run

# Runs using a specific config file
dotnet run my_production_config.xml
```
