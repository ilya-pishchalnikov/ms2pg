using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Policy;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.XPath;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace ms2pg.PgScripter
{
    public class XsltExtensions
    {
        private Config.ConfigProperties _Config;

        private static Dictionary<string, List<ProcedureResultSetColumn>> _ProcedureResultSets;
        private static Dictionary<string, Dictionary<string, string>> _ComputedColumnsTypes;
        private static Dictionary<string, SqlProcedure> _Procedures;

        public XsltExtensions (Config.ConfigProperties config)
        {
            _Config = config;
            if (XsltExtensions._ProcedureResultSets == null)
            {
                XsltExtensions._ProcedureResultSets = new Dictionary<string, List<ProcedureResultSetColumn>>();

                Console.WriteLine("caching...");

                var connectionString = config["ms-connection-string"];
                var filter = config.ContainsKey("file-name-contains-filters") ? config["file-name-contains-filters"] : "";

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

            if (XsltExtensions._Procedures == null)
            {
                XsltExtensions._Procedures = new Dictionary<string, SqlProcedure> ();
                Console.WriteLine("caching procedures...");
                var sql = string.Empty;
                sql += "select\n";
                sql += "\n";
                sql += "      object_schema_name(p.object_id) + '.' + object_name(p.object_id) as procedure_name\n";
                sql += "	, p.parameter_id\n";
                sql += "	, stuff(p.name, 1, 1, '') as parameter_name\n";
                sql += "    , case t.name\n";
                sql += "          when 'int' then 'INT'\n";
                sql += "          when 'binary' then 'BYTEA'\n";
                sql += "          when 'varbinary' then 'BYTEA'\n";
                sql += "          when 'numeric' then concat('NUMERIC (', p.[precision], ',', p.scale, ')')\n";
                sql += "          when 'decimal' then concat('NUMERIC (', p.[precision], ',', p.scale, ')')\n";
                sql += "          when 'varchar' then concat('VARCHAR', iif(p.max_length > 0, '(' + cast(p.max_length as varchar) + ')', ''))\n";
                sql += "          when 'nvarchar' then concat('VARCHAR', iif(p.max_length > 0, cast(p.max_length as varchar) + ')', ''))\n";
                sql += "          when 'char' then concat('CHAR', iif(p.max_length > 0, '(' + cast(p.max_length as varchar) + ')', ''))\n";
                sql += "          when 'nchar' then concat('CHAR', iif(p.max_length > 0, '(' + cast(p.max_length as varchar) + ')', ''))\n";
                sql += "          when 'sysname' then 'VARCHAR(128)'\n";
                sql += "          when 'image' then 'BYTEA'\n";
                sql += "          when 'text' then 'TEXT'\n";
                sql += "          when 'ntext' then 'TEXT'\n";
                sql += "          when 'uniqueidentifier' then 'BYTEA'\n";
                sql += "          when 'date' then 'TIMESTAMP'\n";
                sql += "          when 'datetime' then 'TIMESTAMP'\n";
                sql += "          when 'datetime2' then 'TIMESTAMP'\n";
                sql += "          when 'datetimeoffset' then 'TIMESTAMP'\n";
                sql += "          when 'smalldatetime' then 'TIMESTAMP'\n";
                sql += "          when 'tinyint' then 'INT2'\n";
                sql += "          when 'smallint' then 'INT2'\n";
                sql += "          when 'real' then 'FLOAT'\n";
                sql += "          when 'float' then 'FLOAT'\n";
                sql += "          when 'money' then 'DECIMAL(19, 4)'\n";
                sql += "          when 'smallmoney' then 'DECIMAL(19, 4)'\n";
                sql += "          when 'bit' then 'INT2'\n";
                sql += "          when 'bigint' then 'BIGINT'\n";
                sql += "          else upper(t.name)\n";
                sql += "      end as parameter_type\n";
                sql += "	, p.is_output as parameter_is_output\n";
                sql += "from sys.parameters p\n";
                sql += "inner join sys.types t on t.system_type_id = p.system_type_id and t.user_type_id = p.user_type_id\n";
                sql += "where p.parameter_id > 0\n";
                sql += "order by procedure_name, p.parameter_id\n";

                var connectionString = config["ms-connection-string"];
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    using (var command = new SqlCommand(sql, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var procedureName = (string)reader[0];
                            var parameterId = (int)reader[1];
                            var parameterName = (string)reader[2];
                            var parameterType = (string)reader[3];
                            var parameterIsOutput = (bool)reader[4];
                            if (!XsltExtensions._Procedures.ContainsKey(procedureName.ToLower()))
                            {
                                XsltExtensions._Procedures.Add(procedureName.ToLower(), new SqlProcedure(procedureName));

                            }
                            XsltExtensions._Procedures[procedureName.ToLower()].Parameters.Add(new SqlProcedureParameter(parameterName, parameterType, parameterId, parameterIsOutput));
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
                "char",
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
                return procedureFields.Select(procedureField => $"{QuoteName(procedureField.ColumnName)} {procedureField.DataType}").Aggregate((x, y) => x + ",\n" + y);
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
                return procedureFields.Select(procedureField => $"CAST ({QuoteName(procedureField.ColumnName)} AS {procedureField.DataType})").Aggregate((x, y) => x + ",\n" + y);
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

        public XPathNavigator SplitString (string str, string divider)
        {
            var doc = new XmlDocument();
            var rootElement = doc.CreateElement("root");
            doc.AppendChild(rootElement);
            foreach (var substr in str.Split(divider))
            {
                var substrElement = rootElement.AppendChild(doc.CreateElement("element"));
                substrElement.InnerText = substr;
            }
            return doc.CreateNavigator()!;

        }


        public string GetVariablesForOutputParameters(XPathNodeIterator proceduresIterator)
        {
            var varibalesDefinition = "";
            var procedures = new HashSet<string>();
            while (proceduresIterator.MoveNext())
            {
                XPathNavigator? procedureNavigator = proceduresIterator.Current;

                var schemaName = procedureNavigator.SelectSingleNode("ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/SchemaIdentifier/Identifier")?.GetAttribute("Value", "");
                var objectName = procedureNavigator.SelectSingleNode("ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/BaseIdentifier/Identifier")?.GetAttribute("Value", "");

                var procedureName = $"{schemaName}.{objectName}";
                if (XsltExtensions._Procedures.ContainsKey(procedureName.ToLower()) && !procedures.Contains(procedureName.ToLower()))
                {
                    procedures.Add(procedureName.ToLower());
                    var procedure = XsltExtensions._Procedures[procedureName.ToLower()];
                    int parameterId = 0;

                    var parametersIterator = procedureNavigator.Select("Parameters/*");

                    while (parametersIterator.MoveNext())
                    {
                        XPathNavigator? current = parametersIterator.Current;

                        if (current == null)
                        {
                            break;
                        }

                        string parameterName = current.GetAttribute("Variable", "");
                        string isOutput = current.GetAttribute("IsOutput", "");

                        if (parameterName != null && parameterName != "")
                        {
                            parameterId = procedure.Parameters.Where(p => p.Name == parameterName).First().Id;
                        }
                        else
                        {
                            parameterId++;
                        }

                        SqlProcedureParameter parameter = procedure.Parameters[parameterId - 1];


                        if (parameter.IsOutput && !(isOutput == "True"))
                        {
                            varibalesDefinition += QuoteName($"var_{procedure.Name.Replace(".", "_")}_{parameter.Name}_out");
                            varibalesDefinition += $" {parameter.Type};\n";
                        }
                    }
                }
            }
            return varibalesDefinition;
        }

        public string GetVariablesSetForOutputParameters(XPathNodeIterator procedureIterator)
        {
            var varibalesSet = "";
            while (procedureIterator.MoveNext())
            {
                XPathNavigator? procedureNavigator = procedureIterator.Current;

                var schemaName = procedureNavigator.SelectSingleNode("ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/SchemaIdentifier/Identifier")?.GetAttribute("Value", "");
                var objectName = procedureNavigator.SelectSingleNode("ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/BaseIdentifier/Identifier")?.GetAttribute("Value", "");

                var procedureName = $"{schemaName}.{objectName}";
                if (XsltExtensions._Procedures.ContainsKey(procedureName.ToLower()))
                {
                    var procedure = XsltExtensions._Procedures[procedureName.ToLower()];
                    int parameterId = 0;

                    var parametersIterator = procedureNavigator.Select("Parameters/*");

                    while (parametersIterator.MoveNext())
                    {
                        XPathNavigator? currentParameter = parametersIterator.Current;

                        if (currentParameter == null)
                        {
                            break;
                        }

                        string parameterName = currentParameter.GetAttribute("Variable", "");
                        string isOutput = currentParameter.GetAttribute("IsOutput", "");

                        if (parameterName != null && parameterName != "")
                        {
                            parameterId = procedure.Parameters.Where(p => p.Name == parameterName).First().Id;
                        }
                        else
                        {
                            parameterId++;
                        }

                        SqlProcedureParameter parameter = procedure.Parameters[parameterId - 1];


                        if (parameter.IsOutput && !(isOutput == "True"))
                        {
                            varibalesSet += QuoteName($"var_{procedure.Name.Replace(".", "_")}_{parameter.Name}_out");
                            var parameterValueVariable = currentParameter.SelectSingleNode("ParameterValue/VariableReference");
                            if (parameterValueVariable != null)
                            {
                                varibalesSet += $" := " + QuoteName($"var_{parameterValueVariable.GetAttribute("Name","").Substring(1)}") + ";\n";
                            } else
                            {
                                var parameterValueNull = currentParameter.SelectSingleNode("ParameterValue/NullLiteral");
                                if (parameterValueNull != null)
                                {
                                    varibalesSet += $" := null;\n";
                                }
                                else
                                {
                                    varibalesSet += "/*UNKNOWN PARAMETER VALUE IN GetVariablesSetForOutputParameters*/\n";
                                }
                            }
                        }
                    }
                }
            }
            return varibalesSet;
        }

        public XPathNavigator? GetParameterValueNode(string procedureName, int parameterPosition, XPathNodeIterator parameterNameIterator, XPathNodeIterator parameterValueIterator)
        {

            var isOutputParameter = false;
            var parameterName = "";
            if (XsltExtensions._Procedures.ContainsKey(procedureName.ToLower()))
            {
                var procedure = XsltExtensions._Procedures[procedureName.ToLower()];

                SqlProcedureParameter parameter = null;

                if (parameterNameIterator != null)
                {
                    while (parameterNameIterator.MoveNext())
                    {
                        parameterName = parameterNameIterator.Current!.SelectSingleNode("VariableReference")!.GetAttribute("Name", "").Substring(1);
                        parameter = procedure.Parameters.Where(p => p.Name == parameterName).First();
                    }
                    if (parameter == null)
                    {
                        parameter = procedure.Parameters[parameterPosition - 1];
                    }
                }
                else
                {
                    parameter = procedure.Parameters[parameterPosition - 1];
                }

                isOutputParameter = parameter.IsOutput;
                procedureName = procedure.Name;
                parameterName = parameter.Name;
            }

            while (parameterValueIterator.MoveNext())
            {
                var currentParameterValue = parameterValueIterator.Current!;
                var isOutput = currentParameterValue.SelectSingleNode("parent::*")!.GetAttribute("IsOutput", "");

                if (isOutput == "False" && isOutputParameter)
                {
                    var parameterAssignVarName = QuoteName($"{procedureName.Replace(".", "_")}_{parameterName}_out");
                    var doc = new XmlDocument();
                    var parameterValueElement = doc.CreateElement("ParameterValue");
                    var varElement = doc.CreateElement("VariableReference");
                    varElement.SetAttribute("Name", $"@{parameterAssignVarName}");
                    parameterValueElement.AppendChild(varElement);
                    return parameterValueElement.CreateNavigator();
                }
                return currentParameterValue;
            }

            return null;

        }
    }


}