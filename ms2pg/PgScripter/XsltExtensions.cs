using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Policy;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace ms2pg.PgScripter
{
    public class XsltExtensions
    {
        private Config.Config _Config;

        private static Dictionary<string, List<ProcedureResultSetColumn>> _ProcedureResultSets;
        private static Dictionary<string, Dictionary<string, string>> _ComputedColumnsTypes;

        public XsltExtensions (Config.Config config)
        {
            _Config = config;
            if (XsltExtensions._ProcedureResultSets == null)
            {
                XsltExtensions._ProcedureResultSets = new Dictionary<string, List<ProcedureResultSetColumn>>();

                Console.WriteLine("caching...");

                var connectionString = config["ms-connection-string"];
                var filter = config["file-name-contains-filters"];

                var sql = "select  object_schema_name(o.object_id) + '.' + o.name as object_name\n";
                sql += "        , r.column_ordinal\n";
                sql += "        , r.name as column_name\n";
                sql += "        , r.system_type_name\n";
                sql += "from sys.objects o\n";
                sql += "cross apply sys.dm_exec_describe_first_result_set_for_object ( o.object_id, 0) r\n";
                sql += "where o.[type] = 'P'\n";
                sql += "    and (error_severity < 11 or error_severity is null)\n";
                sql += "    and not exists (select * from sys.parameters p where p.object_id = o.object_id and p.is_output = 1)\n";
                sql += $"   and object_schema_name(o.object_id) + '.' + o.name + '.sql' like '%{filter}%'\n";
                sql += "order by o.object_id, r.column_ordinal;";

                using (var connection = new SqlConnection (connectionString))
                {
                    connection.Open();
                    using (var command = new SqlCommand (sql, connection))
                    {
                        command.CommandTimeout = 1200;
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var procedureName = (string) reader[0];
                                var ordinal = (int) reader[1];
                                var columnName = string.Empty;
                                if (reader[2] == null || reader[2] is DBNull)
                                {
                                    columnName = $"col_{procedureName.Replace(".", "_").Replace("\"", "")}_{ordinal}";
                                }
                                else 
                                {
                                    columnName = (string) reader[2];
                                }
                                var dataType = ((string)reader[3])
                                                .ToUpper()                                        
                                                .Replace("NVARCHAR", "VARCHAR")
                                                .Replace("(MAX)", "")
                                                .Replace("DATETIME", "TIMESTAMP")
                                                .Replace("VARBINARY", "BYTEA")
                                                .Replace("BINARY", "BYTEA");
                                if (!XsltExtensions._ProcedureResultSets.ContainsKey(procedureName))
                                {
                                    XsltExtensions._ProcedureResultSets.Add(procedureName, new List<ProcedureResultSetColumn>());
                                }
                                XsltExtensions._ProcedureResultSets[procedureName].Add(new ProcedureResultSetColumn(procedureName, columnName, dataType));
                            }
                        }
                    }
                }

                if (XsltExtensions._ComputedColumnsTypes == null)
                {
                    sql = "select\n";
                    sql +="    object_schema_name(c.object_id) + '.' + object_name(c.object_id) as table_name,\n";
                    sql +="    c.name as columnName,\n";
                    sql +="    case t.name\n";
                    sql +="        when 'int' then 'INT'\n";
                    sql +="        when 'binary' then 'BYTEA'\n";
                    sql +="        when 'varbinary' then 'BYTEA'\n";
                    sql +="        when 'numeric' then concat ('NUMERIC (', c.[precision], ',', c.scale, ')')\n";
                    sql +="        when 'decimal' then concat ('NUMERIC (', c.[precision], ',', c.scale, ')')\n";
                    sql +="        when 'varchar' then concat ('VARCHAR', IIF(c.max_length > 0, '(' + cast (c.max_length as varchar) + ')', ''))\n";
                    sql +="        when 'nvarchar' then concat ('VARCHAR', IIF(c.max_length > 0, cast (c.max_length as varchar) + ')', ''))\n";
                    sql +="        when 'char' then concat ('CHAR', IIF(c.max_length > 0, '(' + cast (c.max_length as varchar) + ')', ''))\n";
                    sql +="        when 'nchar' then concat ('CHAR', IIF(c.max_length > 0, '(' + cast (c.max_length as varchar) + ')', ''))\n";
                    sql +="        when 'sysname' then 'VARCHAR(128)'\n";
                    sql +="        when 'image' then 'BYTEA'\n";
                    sql +="        when 'text' then 'TEXT'\n";
                    sql +="        when 'ntext' then 'TEXT'\n";
                    sql +="        when 'uniqueidentifier' then 'BYTEA'\n";
                    sql +="        when 'date' then 'TIMESTAMP'\n";
                    sql +="        when 'datetime' then 'TIMESTAMP'\n";
                    sql +="        when 'datetime2' then 'TIMESTAMP'\n";
                    sql +="        when 'datetimeoffset' then 'TIMESTAMP'\n";
                    sql +="        when 'smalldatetime' then 'TIMESTAMP'\n";
                    sql +="        when 'tinyint' then 'INT2'\n";
                    sql +="        when 'smallint' then 'INT2'\n";
                    sql +="        when 'real' then 'FLOAT'\n";
                    sql +="        when 'float' then 'FLOAT'\n";
                    sql +="        when 'money' then 'DECIMAL(19, 4)'\n";
                    sql +="        when 'smallmoney' then 'DECIMAL(19, 4)'\n";
                    sql +="        when 'bit' then 'INT2'\n";
                    sql +="        when 'bigint' then 'BIGINT'\n";
                    sql +="        else upper(t.name)\n";
                    sql +="    end as type\n";
                    sql +="from sys.columns c \n";
                    sql +="inner join sys.types t on t.user_type_id = c.user_type_id and t.system_type_id = c.system_type_id\n";
                    sql +="where is_computed = 1;\n";

                    XsltExtensions._ComputedColumnsTypes = new Dictionary<string, Dictionary<string, string>>();

                    using (var connection = new SqlConnection(connectionString))
                    {
                        connection.Open();
                        using (var command = new SqlCommand(sql, connection))
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var tableName = (string) reader[0];
                                var columnName = (string) reader[1];
                                var columnType = (string) reader[2];
                                if (!XsltExtensions._ComputedColumnsTypes.ContainsKey(tableName))
                                {
                                    XsltExtensions._ComputedColumnsTypes.Add(tableName, new Dictionary<string, string>());
                                }
                                XsltExtensions._ComputedColumnsTypes[tableName].Add(columnName, columnType);
                            }
                        }
                    }
                }                
            }


        }

        private string[] _Keywords = new string[] {
                "all",
                "analyse",
                "analyze",
                "and",
                "any",
                "array",
                "as",
                "asc",
                "asymmetric",
                "both",
                "case",
                "cast",
                "check",
                "collate",
                "column",
                "constraint",
                "create",
                "current_catalog",
                "current_date",
                "current_role",
                "current_time",
                "current_timestamp",
                "current_user",
                "default",
                "deferrable",
                "desc",
                "distinct",
                "do",
                "else",
                "end",
                "except",
                "false",
                "fetch",
                "for",
                "foreign",
                "from",
                "grant",
                "group",
                "having",
                "in",
                "initially",
                "intersect",
                "into",
                "lateral",
                "leading",
                "limit",
                "localtime",
                "localtimestamp",
                "not",
                "null",
                "offset",
                "on",
                "only",
                "or",
                "order",
                "placing",
                "primary",
                "references",
                "returning",
                "select",
                "session_user",
                "some",
                "symmetric",
                "system_user",
                "table",
                "then",
                "to",
                "trailing",
                "true",
                "union",
                "unique",
                "user",
                "using",
                "variadic",
                "when",
                "where",
                "window",
                "with"
            };
        public string QuoteName(string name)
        {            
            if (name.StartsWith('#'))
            {
                return "tmp_" + name.Substring(1);
            }
            else if (Regex.IsMatch(name, "^[^a-zA-Z_].+")
                || Regex.IsMatch(name, "[^a-zA-Z_0-9]")
                || _Keywords.Contains(name.ToLower()))
            {
                return $"\"{name}\"";
            }
            else 
            {
                return name;
            }
        }

        public string ToLower (string str)
        {
            return str.ToLower();
        }

        public string DoubleQuotes (string str)
        {
            return str.Replace("'", "''");
        }

        public string GetTableValuedFunctionTableDefinition (string functionName)
        {
            try
            {
                var functionFields = GetFunctionFields(functionName);
                return functionFields.Select(functionField => $"{functionField[0]} {functionField[1]}").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }

        public string GetTableValuedFunctionQueryFieldsDefinition (string functionName)
        {
            try
            {
                var functionFields = GetFunctionFields(functionName);
                return functionFields.Select(functionField => $"CAST ({functionField[0]} AS {functionField[1]})").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }

        public bool IsProcedureHasResultSet (string procedureName)
        {
            return _ProcedureResultSets.ContainsKey(procedureName);
        }   

        
        public string GetProcedureTableDefinition (string procedureName)
        {
            try
            {
                var procedureFields = _ProcedureResultSets[procedureName];
                return procedureFields.Select(procedureField => $"{procedureField.ColumnName} {procedureField.DataType}").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }

        public string GetProcedureQueryFieldsDefinition (string procedureName)
        {
            try
            {
                var procedureFields = _ProcedureResultSets[procedureName];
                return procedureFields.Select(procedureField => $"CAST ({procedureField.ColumnName} AS {procedureField.DataType})").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }

        public string Replace(string str, string replacing, string replacement)
        {
            return str.Replace(replacing, replacement);
        }
        public bool Contains (string str, string substr)
        {
            return str.Contains(substr);
        }
        public bool StartsWith (string str, string substr)
        {
            return str.StartsWith(substr);
        }

        public string GetComputedColumnType (string tableName, string columnName)
        {
            if (XsltExtensions._ComputedColumnsTypes.ContainsKey(tableName) && XsltExtensions._ComputedColumnsTypes[tableName].ContainsKey(columnName))
            {
                return XsltExtensions._ComputedColumnsTypes[tableName][columnName];
            }
            else 
            {
                return "VARCHAR";
            }
        }

        private List<List<string>> GetFunctionFields (string functionName)
        {
            var result = new List<List<string>>();
            var connectionString = _Config["ms-connection-string"];
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var sql = $"select count (*) from sys.parameters where object_id = object_id('{functionName}')";
                var parametersCount = 0;

                using (var command = new SqlCommand (sql, connection))
                {
                    parametersCount = (int)command.ExecuteScalar();
                }

                var parameters = string.Empty;
                for (int i = 0; i < parametersCount; i++)
                {
                    if (i > 0) parameters += ", ";
                    parameters += "default";
                }

                sql = "select top (0) *\n";
                sql += $"from {functionName}({parameters});\n";

                using (var command = new SqlCommand (sql, connection))
                using (var reader  = command.ExecuteReader())
                {
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var fieldDefinition = new List<string>(2);
                        fieldDefinition.Add (QuoteName(reader.GetName(i)));
                        var fieldType = reader.GetFieldType(i);
                        switch (fieldType.Name)
                        {
                            case "Int32":
                                fieldDefinition.Add ("INT");
                                break;
                            case "Int64":
                                fieldDefinition.Add ("BIGINT");
                                break;
                            case "String":
                                fieldDefinition.Add ("TEXT");
                                break;
                            case "DateTime":
                                fieldDefinition.Add ("TIMESTAMP");
                                break;
                            default:
                                fieldDefinition.Add (fieldType.Name);
                                break;
                        }
                        result.Add(fieldDefinition);
                    }
                }
            }
            return result;
        }
    }
}