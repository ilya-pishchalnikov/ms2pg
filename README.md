# ms2pg: Microsoft SQL Server to PostgreSQL Migration Tool

`ms2pg` is a dedicated command-line utility for migrating database objects and data from **Microsoft SQL Server (MS SQL)** to **PostgreSQL (PgSQL)**.

It handles the complex process of scripting MS SQL objects, parsing T-SQL syntax, transforming it into PostgreSQL-compatible SQL using XSLT templates, and deploying the results with built-in error resolution.

## :warning: Licensing Information

This software is provided "as is" and its commercial use is **strictly prohibited**. Please review the `LICENSE` file for full terms and conditions.

## Key Features

-   **Full Migration Cycle:** Scripts objects from MS SQL, parses them to an intermediate XML AST, transforms the XML to PgSQL, deploys the PgSQL scripts, and migrates table data.
-   **T-SQL Parsing:** Utilizes the official Microsoft `ScriptDom` (`TSql160Parser`) for accurate T-SQL parsing.
-   **XSLT-based Transformation:** Uses modular XSLT templates (`ms2pg.xslt`, `createtable.xslt`, etc.) for flexible and maintainable translation of SQL syntax (e.g., data types, expressions, procedure logic).
-   **Procedure/Function Conversion:** Smartly converts MS SQL Stored Procedures into PostgreSQL functions (returning `TABLE(...)`) or procedures, based on whether they return a result set.
-   **Automated Deployment:** Deploys generated PgSQL scripts to the target database, handling batches and a retry mechanism.
-   **Error Solver:** Includes basic logic (`ErrorsSolver.cs`) to fix known PgSQL deployment issues, such as those flagged by the `plpgsql_check` extension (using the `{{CHECK ERROR}}` marker).
-   **Efficient Data Migration:** Uses `Npgsql`'s binary import feature for fast, bulk data transfer from MS SQL to PgSQL.
-   **Configuration-driven:** The entire workflow is controlled via an XML configuration file (`config.xml`), allowing users to enable/disable specific steps.

## System Requirements

-   **.NET Runtime:** The application is built on C\# and requires a compatible .NET runtime (likely .NET Framework or .NET Core/5+ based on dependencies like `Microsoft.Data.SqlClient` and `Npgsql`).
-   **MS SQL Server Management Objects (SMO) Libraries:** Required for the scripting phase (`ObjectsScripter.cs`).
-   **PostgreSQL:** Target database instance.
-   **plpgsql_check (Recommended):** The deployment process includes checks that utilize the `plpgsql_check` extension for functions and procedures.

## Workflow Overview

The entire process is a pipeline executed through a series of configurable actions:

1.  **`clear-folder`**: Cleans up output directories.
2.  **`ScriptMsSql`**: Connects to MS SQL (via SMO) and scripts all database objects into `.sql` files in the `ms-script-dir`.
3.  **`ParseMsSql`**: Reads T-SQL `.sql` files, parses them using `TSql160Parser`, serializes the AST to `.xml` files in the `ms-parsed-dir`.
4.  **`ScriptPgSql`**: Transforms the `.xml` AST files into PgSQL `.sql` files (in `pg-script-dir`) using the XSLT templates.
5.  **`DeployPgSql`**: Connects to PostgreSQL and executes the generated scripts, using `ErrorsSolver` to handle specific exceptions.
6.  **`DataMigration`**: Transfers data from tables in MS SQL to PgSQL using binary bulk copy.

## Usage

### 1\. Configuration File (`config.xml`)

The tool is controlled by a configuration file, typically `config.xml`. This file defines connection strings and the sequence of migration steps (`actions`).

**Example Structure:**

```xml
<ms2pg-config>
    <common>
        <property name="ms-connection-string" value="Server=MSSQLSERVER;Database=SourceDb;..." />
        <property name="pg-connection-string" value="Host=localhost;Database=TargetDb;User Id=user;Password=pass;" />
        <property name="ms-script-dir" value="scripts/mssql" />
        <property name="ms-parsed-dir" value="scripts/ms-parsed" />
        <property name="pg-script-dir" value="scripts/pgsql" />
        <property name="xslt-file-name" value="ms2pg.xslt" />
        <property name="errors-limit" value="10" />
    </common>
    <actions>
        <action type="clear-folder" name="Clear PgSQL scripts" enabled="true">
            <property name="dir" property-value="pg-script-dir" />
        </action>
        <action type="ScriptMsSql" name="Script MsSql Objects" enabled="true" />
        <action type="ParseMsSql" name="Parse MsSql Script to XML" enabled="true" />
        <action type="ScriptPgSql" name="Generate PgSQL Script" enabled="true" />
        <action type="DeployPgSql" name="Deploy PgSQL Script" enabled="true" />
        </actions>
</ms2pg-config>
```

### 2\. Execution

Run the application from the command line:

```bash
# Run with default config.xml
ms2pg.exe

# Run with a custom configuration file
ms2pg.exe custom_config.xml
```

The application will execute all actions marked `enabled="true"` in the order they are defined in the configuration file. Execution timings for each step will be printed to the console.

## Customization: XSLT Templates

The conversion logic is entirely contained within the XSLT files. To adapt to specific T-SQL syntax or PostgreSQL versions, you should modify these files:

| File                   | Purpose                               | Key Customization Areas                                                                                          |
| :--------------------- | :------------------------------------ | :--------------------------------------------------------------------------------------------------------------- |
| `ms2pg.xslt`           | Main entry point; imports all others. | Defines the overall script structure and batching logic (`{{GO}}`).                                              |
| `common.xslt`          | Global utility templates.             | Defines indentation markers (`{{Indent++}}`, `{{Indent--}}`) and statement separators.                           |
| `datatypes.xslt`       | Data type mapping.                    | Modify conversion rules (e.g., `VARCHAR` to `TEXT`, handling `IDENTITY` as `SERIAL`).                            |
| `expression.xslt`      | Function/Expression mapping.          | Adjust translations for built-in functions (e.g., `@@ROWCOUNT` to `pg_affected_rows()`, `GETDATE()` to `NOW()`). |
| `createprocedure.xslt` | Stored Procedure conversion.          | Logic for determining if a procedure needs to be a function returning `TABLE`.                                   |
| `createtable.xslt`     | Table creation.                       | Handling of temporal tables, `IF NOT EXISTS` clauses, and inline constraints.                                    |
| `settings.xslt`        | Global XSLT variables.                | Contains boolean flags like `$skip_dbo_in_object_identifiers` and `$create_table_if_not_exists`.                 |

### XSLT Extension Functions

The XSLT transformation uses extension functions exposed via `XsltExtensions.cs` (namespace `urn:ms2pg`) to interact with the MS SQL source during conversion:

| Function                                       | C\# Method                          | Description                                                                                                             |
| :--------------------------------------------- | :---------------------------------- | :---------------------------------------------------------------------------------------------------------------------- |
| `ms2pg:IsProcedureHasResultSet(procName)`      | `IsProcedureHasResultSet`           | Queries MS SQL to check if a Stored Procedure returns a result set (used in `createprocedure.xslt`).                    |
| `ms2pg:GetProcedureQueryFieldsDefinition(...)` | `GetProcedureQueryFieldsDefinition` | Retrieves the column definitions for a procedure's result set to define the PostgreSQL function's `RETURNS TABLE(...)`. |
| `ms2pg:RegexReplace(...)`                      | `RegexReplace`                      | Utility function for string replacement using regular expressions.                                                      |
| `ms2pg:SplitString(...)`                       | `SplitString`                       | Splits a string by a delimiter and returns an XML fragment for iteration.                                               |
